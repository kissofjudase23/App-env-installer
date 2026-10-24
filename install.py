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
from datetime import datetime
from enum import Enum, unique
from pathlib import Path
from typing import NoReturn

import click
import prettytable as pt
import yaml

ROOT = Path(__file__).resolve().parent

NERD_FONTS_RELEASE_API = "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"

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


# /etc/os-release ID values
@unique
class LinuxDistributions(Enum):
    UBUNTU = "ubuntu"


def run(cmd: list[str], *, dry_run: bool) -> None:
    click.echo(f"$ {' '.join(cmd)}")
    if not dry_run:
        subprocess.run(cmd, check=True)


def fetch(url: str) -> bytes:
    with urllib.request.urlopen(url, timeout=60) as resp:
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

        dsts: set[str] = set()
        for key in ("dotfiles", "git_repos"):
            for entry in self._list(key):
                valid = isinstance(entry, dict) and all(
                    isinstance(entry.get(k), str) for k in ("src", "dst")
                )
                if not valid:
                    fail(f"{key} entry needs string src and dst: {entry}")
                dst = Path(entry["dst"])
                if dst.is_absolute() or ".." in dst.parts or not dst.parts:
                    fail(f"{key} dst must be a path inside $HOME: {entry['dst']!r}")
                if str(dst) in dsts:
                    fail(f"duplicate dst: {dst}")
                dsts.add(str(dst))
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
        assume_yes: bool = False,
        dry_run: bool = False,
    ):
        self.home = home
        self.system = system
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

    def clone_git_repos(self) -> None:
        pairs = [(repo["src"], self.home / repo["dst"]) for repo in self.config_mgr.git_repos]
        if not self._confirm("Prepare to clone git repos", pairs):
            return

        for src, dst in pairs:
            self.git_agent.clone(src, dst)

    def link_dotfiles(self) -> None:
        pairs = [(ROOT / f["src"], self.home / f["dst"]) for f in self.config_mgr.dotfiles]
        if not self._confirm("Prepare to link dotfiles", pairs):
            return

        for src, dst in pairs:
            if dst.is_symlink() and dst.resolve() == src.resolve():
                click.echo(f"skip {dst}: already linked")
                continue

            click.echo(f"link {src} -> {dst}")
            if self.dry_run:
                continue

            dst.parent.mkdir(parents=True, exist_ok=True)
            if dst.is_symlink():
                dst.unlink()
            elif dst.exists():
                backup = dst.with_name(f"{dst.name}.bak.{datetime.now():%Y%m%d%H%M%S}")
                click.echo(f"backup {dst} -> {backup}")
                dst.rename(backup)
            dst.symlink_to(src)

    def ensure_gitconfig_local(self) -> None:
        path = self.home / ".gitconfig.local"
        if path.exists():
            return
        click.echo(f"create {path}: set your git user.name/user.email there")
        if not self.dry_run:
            path.write_text(GITCONFIG_LOCAL_TEMPLATE, encoding="utf-8")

    def install_fonts(self) -> None:
        # macOS fonts are installed by the Brewfile
        if self.system != SupportedSystems.LINUX.value:
            return

        font_dir = self.home / ".local/share/fonts/NerdFonts"
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
@click.option("-f", "--fonts", "install_fonts", is_flag=True, help="Install fonts (Linux only).")
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
