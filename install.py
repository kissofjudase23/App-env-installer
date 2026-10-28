import hashlib
import io
import json
import os
import platform
import shutil
import subprocess
import sys
import tarfile
import urllib.request
import uuid
from datetime import datetime
from enum import Enum, unique
from pathlib import Path
from typing import NoReturn

import click
import prettytable as pt
import yaml

ROOT = Path(__file__).resolve().parent

GITHUB_API = "https://api.github.com/"
NERD_FONTS_RELEASE_API = f"{GITHUB_API}repos/ryanoasis/nerd-fonts/releases/latest"

WINDOWS_FONTS_KEY = r"Software\Microsoft\Windows NT\CurrentVersion\Fonts"
# Known folder API follows OneDrive/GPO redirection, unlike ~/Documents
FOLDERID_DOCUMENTS = uuid.UUID("FDD39AD0-238F-46AF-ADB4-6C85480369C7")
# winerror when creating a symlink without Developer Mode or admin rights
ERROR_PRIVILEGE_NOT_HELD = 1314

GITCONFIG_LOCAL_TEMPLATE = """\
# Machine-specific git settings (not tracked). Uncomment and set your identity.
# [user]
#     name = Your Name
#     email = you@example.com
"""


class InstallerError(Exception):
    pass


class NotSupportError(InstallerError):
    pass


@unique
class SupportedSystems(Enum):
    DARWIN = "Darwin"
    LINUX = "Linux"
    WINDOWS = "Windows"


# config.yaml `os` values are the lowercase platform.system() names
OS_NAMES = frozenset(s.value.lower() for s in SupportedSystems)
# config.yaml `base` values: the directory a dst is relative to
BASES = ("home", "documents")


# /etc/os-release ID values
@unique
class LinuxDistributions(Enum):
    UBUNTU = "ubuntu"


def _stub_header(src: Path) -> str:
    return f"# Managed by App-env-installer; edit {src.as_posix()} instead\n"


def _ps_quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


# Windows dotfiles are small files that include the repo file, so no symlink privilege is needed
STUBS = {
    "gitconfig": lambda src: f'{_stub_header(src)}[include]\n    path = "{src.as_posix()}"\n',
    "powershell": lambda src: f"{_stub_header(src)}. {_ps_quote(str(src))}\n",
}


def run(cmd: list[str], *, dry_run: bool) -> None:
    click.echo(f"$ {' '.join(cmd)}")
    if not dry_run:
        subprocess.run(cmd, check=True)


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url)
    # A token lifts GitHub's anonymous rate limit; unredirected so downloads never receive it
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token and url.startswith(GITHUB_API):
        req.add_unredirected_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def extract_fonts(archive: bytes, dst: Path) -> None:
    # Extract into a sibling temp dir first so a failed run never looks installed
    tmp = dst.with_name(f".{dst.name}.tmp")
    shutil.rmtree(tmp, ignore_errors=True)
    tmp.mkdir(parents=True)
    try:
        with tarfile.open(fileobj=io.BytesIO(archive), mode="r:xz") as tar:
            members = [m for m in tar.getmembers() if m.isfile() and m.name.endswith(".ttf")]
            tar.extractall(tmp, members=members, filter="data")
    except tarfile.TarError as e:
        shutil.rmtree(tmp)
        raise InstallerError(f"cannot extract fonts to {dst}: {e}") from e
    shutil.rmtree(dst, ignore_errors=True)
    tmp.rename(dst)


def is_wsl() -> bool:
    return "microsoft" in platform.uname().release.lower()


def windows_documents() -> Path:
    import ctypes

    guid = (ctypes.c_byte * 16).from_buffer_copy(FOLDERID_DOCUMENTS.bytes_le)
    path = ctypes.c_void_p()
    shell32 = ctypes.windll.shell32
    hresult = shell32.SHGetKnownFolderPath(ctypes.byref(guid), 0, None, ctypes.byref(path))
    try:
        if hresult != 0:
            raise InstallerError(f"cannot resolve the Documents folder (HRESULT {hresult:#x})")
        return Path(ctypes.wstring_at(path.value))
    finally:
        ctypes.windll.ole32.CoTaskMemFree(path)


def register_windows_font(ttf: Path) -> None:
    import winreg

    access = winreg.KEY_SET_VALUE
    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, WINDOWS_FONTS_KEY, 0, access) as key:
        winreg.SetValueEx(key, f"{ttf.stem} (TrueType)", 0, winreg.REG_SZ, str(ttf))


def default_base_dirs(home: Path, system: str) -> dict[str, Path]:
    if system != SupportedSystems.WINDOWS.value:
        return {"home": home, "documents": home, "local_app_data": home / ".local/share"}
    return {
        "home": home,
        "documents": windows_documents(),
        "local_app_data": Path(os.environ["LOCALAPPDATA"]),
    }


class GitAgent:
    def __init__(self, *, dry_run: bool = False):
        self.dry_run = dry_run

    def clone(self, repo: str, dst: Path) -> None:
        if (dst / ".git").is_dir():
            click.echo(f"skip {dst}: already cloned")
            return
        if not self.dry_run:
            dst.parent.mkdir(parents=True, exist_ok=True)
        run(["git", "clone", "--recurse-submodules", repo, str(dst)], dry_run=self.dry_run)


class ConfigMgr:
    LISTS = ("dotfiles", "git_repos", "nerd_fonts", "go_tools")

    def __init__(self, config_path: Path = ROOT / "config.yaml"):
        try:
            with open(config_path, encoding="utf-8") as fd:
                self.config = yaml.safe_load(fd) or {}
        except yaml.YAMLError as e:
            raise InstallerError(f"cannot parse {config_path}: {e}") from e
        self._validate(config_path)

    def _validate(self, path: Path) -> None:
        def fail(msg: str) -> NoReturn:
            raise InstallerError(f"{path}: {msg}")

        if not isinstance(self.config, dict):
            fail("top level must be a mapping")
        if unknown := sorted(set(self.config) - set(self.LISTS)):
            fail(f"unknown keys {unknown}")
        for key in self.LISTS:
            if not isinstance(self.config.get(key) or [], list):
                fail(f"{key} must be a list")

        # (base, dst) -> os sets claiming it; entries for disjoint OSes may share a dst
        dsts: dict[tuple[str, str], list[set[str]]] = {}
        for key in ("dotfiles", "git_repos"):
            for entry in self._list(key):
                valid = isinstance(entry, dict) and all(
                    isinstance(entry.get(k), str) for k in ("src", "dst")
                )
                if not valid:
                    fail(f"{key} entry needs string src and dst: {entry}")
                dst = Path(entry["dst"])
                # anchor, not is_absolute(): on Windows "/tmp" has a root but no drive
                if dst.anchor or ".." in dst.parts or not dst.parts:
                    fail(f"{key} dst must be a path inside $HOME: {entry['dst']!r}")

                systems = entry.get("os", sorted(OS_NAMES))
                if not (isinstance(systems, list) and systems and set(systems) <= OS_NAMES):
                    fail(f"{key} os must be a non-empty list of {sorted(OS_NAMES)}: {entry}")
                base = entry.get("base", "home")
                if base not in BASES:
                    fail(f"{key} base must be one of {list(BASES)}: {entry}")
                if "stub" in entry and (key != "dotfiles" or entry["stub"] not in STUBS):
                    fail(f"stub must be a dotfile with one of {sorted(STUBS)}: {entry}")

                claimed = dsts.setdefault((base, str(dst)), [])
                if any(other & set(systems) for other in claimed):
                    fail(f"duplicate dst: {dst}")
                claimed.append(set(systems))
                if key == "dotfiles" and not (ROOT / entry["src"]).exists():
                    fail(f"dotfile src not found: {entry['src']}")

        for key in ("nerd_fonts", "go_tools"):
            if not all(isinstance(item, str) for item in self._list(key)):
                fail(f"{key} entries must be strings")

    def _list(self, key: str) -> list:
        return self.config.get(key) or []

    @property
    def dotfiles(self) -> list[dict]:
        return self._list("dotfiles")

    @property
    def git_repos(self) -> list[dict]:
        return self._list("git_repos")

    @property
    def go_tools(self) -> list[str]:
        return self._list("go_tools")

    @property
    def nerd_fonts(self) -> list[str]:
        return self._list("nerd_fonts")


class Installer:
    def __init__(
        self,
        *,
        home: Path,
        system: str,
        git_agent: GitAgent,
        config_mgr: ConfigMgr,
        base_dirs: dict[str, Path] | None = None,
        assume_yes: bool = False,
        dry_run: bool = False,
    ):
        self.home = home
        self.system = system
        self.base_dirs = base_dirs if base_dirs is not None else default_base_dirs(home, system)
        self.git_agent = git_agent
        self.config_mgr = config_mgr
        self.assume_yes = assume_yes
        self.dry_run = dry_run

    def _confirm(self, title: str, pairs: list[tuple]) -> bool:
        click.echo(f"\n{title}:")
        tb = pt.PrettyTable()
        tb.field_names = ["src", "dst"]
        tb.add_rows([[str(src), str(dst)] for src, dst in pairs])
        click.echo(tb)
        return self.assume_yes or click.confirm("Do you want to continue?", default=False)

    def _entries(self, key: str) -> list[dict]:
        system = self.system.lower()
        return [e for e in getattr(self.config_mgr, key) if system in e.get("os", OS_NAMES)]

    def _dst(self, entry: dict) -> Path:
        return self.base_dirs[entry.get("base", "home")] / entry["dst"]

    def clone_git_repos(self) -> None:
        pairs = [(repo["src"], self._dst(repo)) for repo in self._entries("git_repos")]
        if not self._confirm("Prepare to clone git repos", pairs):
            return

        for src, dst in pairs:
            self.git_agent.clone(src, dst)

    def link_dotfiles(self) -> None:
        entries = self._entries("dotfiles")
        pairs = [(ROOT / f["src"], self._dst(f)) for f in entries]
        if not self._confirm("Prepare to link dotfiles", pairs):
            return

        for entry, (src, dst) in zip(entries, pairs, strict=True):
            stub = STUBS[entry["stub"]](src) if "stub" in entry else None
            if stub is None:
                linked = dst.is_symlink() and dst.resolve() == src.resolve()
            else:
                linked = (
                    not dst.is_symlink()
                    and dst.is_file()
                    and dst.read_text(encoding="utf-8", errors="replace") == stub
                )
            if linked:
                click.echo(f"skip {dst}: already linked")
                continue

            click.echo(f"{'link' if stub is None else 'stub'} {src} -> {dst}")
            if self.dry_run:
                continue

            dst.parent.mkdir(parents=True, exist_ok=True)
            if dst.is_symlink():
                dst.unlink()
            elif dst.exists():
                backup = dst.with_name(f"{dst.name}.bak.{datetime.now():%Y%m%d%H%M%S}")
                click.echo(f"backup {dst} -> {backup}")
                dst.rename(backup)
            if stub is not None:
                dst.write_text(stub, encoding="utf-8", newline="\n")
                continue
            try:
                dst.symlink_to(src)
            except OSError as e:
                if getattr(e, "winerror", None) != ERROR_PRIVILEGE_NOT_HELD:
                    raise
                raise InstallerError(
                    f"cannot symlink {dst}: give the entry a stub or an os list without windows"
                ) from e

    def ensure_gitconfig_local(self) -> None:
        path = self.home / ".gitconfig.local"
        if path.exists():
            return
        click.echo(f"create {path}: set your git user.name/user.email there")
        if not self.dry_run:
            path.write_text(GITCONFIG_LOCAL_TEMPLATE, encoding="utf-8")

    def install_fonts(self) -> None:
        linux = self.system == SupportedSystems.LINUX.value
        if linux and is_wsl():
            click.echo("skip fonts: WSL terminals use fonts installed on the Windows side")
            return
        if linux:
            font_dir = self.home / ".local/share/fonts/NerdFonts"
        elif self.system == SupportedSystems.WINDOWS.value:
            font_dir = self.base_dirs["local_app_data"] / "Microsoft/Windows/Fonts/NerdFonts"
        else:
            # macOS fonts are installed by the Brewfile
            return
        missing = []
        for name in self.config_mgr.nerd_fonts:
            if any((font_dir / name).glob("*.ttf")):
                click.echo(f"skip {font_dir / name}: already installed")
            else:
                missing.append(name)
        if not missing:
            return

        # dry run stays offline: report the archives without resolving the release
        assets = {} if self.dry_run else self._nerd_font_assets()
        for name in missing:
            archive = f"{name}.tar.xz"
            click.echo(f"download nerd-fonts {archive} -> {font_dir / name}")
            if self.dry_run:
                continue
            if archive not in assets:
                raise InstallerError(f"nerd-fonts release has no {archive}")
            url, digest = assets[archive]
            if not digest.startswith("sha256:"):
                raise InstallerError(f"nerd-fonts release has no sha256 digest for {archive}")
            data = fetch(url)
            if f"sha256:{hashlib.sha256(data).hexdigest()}" != digest:
                raise InstallerError(f"sha256 mismatch for {archive}")
            extract_fonts(data, font_dir / name)
            if not linux:
                for ttf in sorted((font_dir / name).glob("*.ttf")):
                    register_windows_font(ttf)

        if linux:
            run(["fc-cache", "-f", str(font_dir)], dry_run=self.dry_run)

    @staticmethod
    def _nerd_font_assets() -> dict[str, tuple[str, str]]:
        release = json.loads(fetch(NERD_FONTS_RELEASE_API))
        click.echo(f"nerd-fonts {release['tag_name']}")
        return {
            a["name"]: (a["browser_download_url"], a.get("digest") or "") for a in release["assets"]
        }

    def install_go_tools(self) -> None:
        go = shutil.which("go")
        if go is None and not self.dry_run:
            click.echo("skip go tools: go not found in PATH", err=True)
            return

        gobin = (
            os.environ.get("GOBIN")
            or Path(os.environ.get("GOPATH", "").split(os.pathsep)[0] or self.home / "go") / "bin"
        )
        pairs = [(pkg, gobin) for pkg in self.config_mgr.go_tools]
        if not self._confirm("Prepare to install go tools", pairs):
            return

        for pkg, _ in pairs:
            run([go or "go", "install", pkg], dry_run=self.dry_run)


def check_supported() -> str:
    system = platform.system()
    click.echo(f"System is {system}")

    if system not in {s.value for s in SupportedSystems}:
        raise NotSupportError(f"does not support {system}")

    if system == SupportedSystems.LINUX.value:
        try:
            os_release = platform.freedesktop_os_release()
        except OSError as e:
            raise NotSupportError(f"cannot determine Linux distribution: {e}") from e
        distro_id = os_release.get("ID", "unknown")
        click.echo(f"Linux distribution is {distro_id}:{os_release.get('VERSION_ID', '')}")
        if distro_id not in {d.value for d in LinuxDistributions}:
            raise NotSupportError(f"does not support {distro_id}")

    return system


@click.command(context_settings={"help_option_names": ["-h", "--help"]})
@click.option(
    "-d",
    "--dotfiles",
    "link_dotfiles",
    is_flag=True,
    help="Link dotfiles into $HOME (default when no action is given).",
)
@click.option("-g", "--git", "clone_git_repos", is_flag=True, help="Clone git repositories.")
@click.option("-f", "--fonts", "install_fonts", is_flag=True, help="Install fonts (not macOS).")
@click.option("-t", "--go-tools", "install_go_tools", is_flag=True, help="Install Go tools.")
@click.option("-a", "--all", "install_all", is_flag=True, help="Run all actions.")
@click.option("-y", "--yes", "assume_yes", is_flag=True, help="Skip confirmation prompts.")
@click.option("--dry-run", is_flag=True, help="Print actions without changing anything.")
def cli(
    link_dotfiles: bool,
    clone_git_repos: bool,
    install_fonts: bool,
    install_go_tools: bool,
    install_all: bool,
    assume_yes: bool,
    dry_run: bool,
) -> None:
    if not (link_dotfiles or clone_git_repos or install_fonts or install_go_tools or install_all):
        link_dotfiles = True

    try:
        installer = Installer(
            home=Path.home(),
            system=check_supported(),
            git_agent=GitAgent(dry_run=dry_run),
            config_mgr=ConfigMgr(),
            assume_yes=assume_yes,
            dry_run=dry_run,
        )

        if install_all or link_dotfiles:
            installer.link_dotfiles()
            installer.ensure_gitconfig_local()

        if install_all or install_fonts:
            installer.install_fonts()

        if install_all or clone_git_repos:
            installer.clone_git_repos()

        if install_all or install_go_tools:
            installer.install_go_tools()
    except (InstallerError, subprocess.CalledProcessError, OSError) as e:
        click.echo(f"error: {e}", err=True)
        sys.exit(1)


if __name__ == "__main__":
    cli()
