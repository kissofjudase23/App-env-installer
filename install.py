# pylint: disable=missing-module-docstring, missing-class-docstring, missing-function-docstring
import platform
import subprocess
import sys
import urllib.request
from datetime import datetime
from enum import Enum, unique
from pathlib import Path
from urllib.parse import quote

import click
import distro
import prettytable as pt
import yaml

ROOT = Path(__file__).resolve().parent

MESLO_FONT_URL = "https://github.com/romkatv/powerlevel10k-media/raw/master/"
MESLO_FONTS = (
    "MesloLGS NF Regular.ttf",
    "MesloLGS NF Bold.ttf",
    "MesloLGS NF Italic.ttf",
    "MesloLGS NF Bold Italic.ttf",
)

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


@unique
class LinuxDistributions(Enum):
    UBUNTU = "Ubuntu"


def run(cmd: list[str], *, dry_run: bool) -> None:
    click.echo(f"$ {' '.join(cmd)}")
    if not dry_run:
        subprocess.run(cmd, check=True)


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
    def __init__(self, config_path: Path = ROOT / "config.yaml"):
        with open(config_path, encoding="utf-8") as fd:
            self.config = yaml.safe_load(fd)

    @property
    def dotfiles(self) -> list[dict]:
        return self.config["dotfiles"]

    @property
    def git_repos(self) -> list[dict]:
        return self.config["git_repos"]


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

        font_dir = self.home / ".local/share/fonts"
        if not self.dry_run:
            font_dir.mkdir(parents=True, exist_ok=True)

        for name in MESLO_FONTS:
            dst = font_dir / name
            if dst.exists():
                click.echo(f"skip {dst}: already exists")
                continue
            url = MESLO_FONT_URL + quote(name)
            click.echo(f"download {url} -> {dst}")
            if not self.dry_run:
                urllib.request.urlretrieve(url, dst)

        run(["fc-cache", "-f", str(font_dir)], dry_run=self.dry_run)


def check_supported() -> str:
    system = platform.system()
    click.echo(f"System is {system}")

    if system not in {s.value for s in SupportedSystems}:
        raise NotSupportError(f"does not support {system}")

    if system == SupportedSystems.LINUX.value:
        distrib_name = distro.name()
        click.echo(f"Linux distribution is {distrib_name}:{distro.version()}")
        if distrib_name not in {d.value for d in LinuxDistributions}:
            raise NotSupportError(f"does not support {distrib_name}")

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
@click.option("-a", "--all", "install_all", is_flag=True, help="Run all actions.")
@click.option("-y", "--yes", "assume_yes", is_flag=True, help="Skip confirmation prompts.")
@click.option("--dry-run", is_flag=True, help="Print actions without changing anything.")
def cli(
    link_dotfiles: bool,
    clone_git_repos: bool,
    install_fonts: bool,
    install_all: bool,
    assume_yes: bool,
    dry_run: bool,
) -> None:
    if not (link_dotfiles or clone_git_repos or install_fonts or install_all):
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
    except (InstallerError, subprocess.CalledProcessError, OSError) as e:
        click.echo(f"error: {e}", err=True)
        sys.exit(1)


if __name__ == "__main__":
    cli()
