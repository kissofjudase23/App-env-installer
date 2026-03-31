# pylint: disable=missing-module-docstring, missing-class-docstring, missing-function-docstring
import os
import platform
import shlex
import subprocess
import time
import urllib.request
from enum import Enum, unique
from pathlib import Path

import click
import distro
import prettytable as pt
import yaml


class BaseError(Exception):
    pass


class NotSupportError(BaseError):
    pass


class InstallPkgError(BaseError):
    pass


class SubProcessError(InstallPkgError):
    pass


@unique
class SupportedSystems(Enum):
    DARWIN = "Darwin"
    LINUX = "Linux"


@unique
class LinuxDistributions(Enum):
    UBUNTU = "Ubuntu"


class SubProcess:
    @staticmethod
    def run_get_ret(cmd):
        return subprocess.run(cmd, stdout=subprocess.DEVNULL).returncode

    @staticmethod
    def run(cmd, *, shell=False, user_input=None):
        print(f"subprocess cmd: {cmd}")
        # redirect std.err to std.out
        # when set input in subprocess.run, the internal
        # stdin is subprocess.PIPE
        # check=True is equal to p.check_returncode()
        subprocess.run(cmd, shell=shell, input=user_input, encoding="utf-8", check=True)


class FileUtils:
    @staticmethod
    def check_and_create_dir(dir_path):
        """
        Create the dir if it does not exist
        p.mkdir(parents=True, exist_ok=True) may be a better solution.
        """
        p = Path(dir_path)
        if p.is_dir():
            # alreasdy exists
            return True

        # create the parent dir
        p.mkdir(parents=True, exist_ok=True)
        return False

    @staticmethod
    def create_dir(dir_path):
        p = Path(dir_path)
        p.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def delete_file(file_path):
        if not os.path.isfile(file_path):
            return
        os.unlink(file_path)

    @staticmethod
    def delete_link(link_path):
        if not os.path.islink(link_path):
            return
        os.unlink(link_path)


class GitAgent:
    @classmethod
    def clone(cls, repo, dst_path, *, check=True):
        if check and FileUtils.check_and_create_dir(dst_path):
            return
        cmd = ("git", "clone", "--recurse-submodules", repo, dst_path)
        SubProcess.run(cmd)


class ConfigMgr:
    def __init__(self, config_path="config.yaml"):
        with open(config_path, "r", encoding="utf-8") as fd:
            self.config = yaml.safe_load(fd)

    @property
    def dotfiles(self):
        return self.config["dotfiles"]

    @property
    def git_repos(self):
        return self.config["git_repos"]


class Installer:
    def __init__(
        self,
        *,
        home,
        system,
        distrib_name,
        distrib_ver,
        git_agent: GitAgent,
        config_mgr: ConfigMgr,
    ):

        self.home = home
        self.system = system
        self.distrib_name = distrib_name
        self.distrib_ver = distrib_ver
        self.cwd = os.path.abspath(os.getcwd())
        self.git_agent = git_agent
        self.config_mgr = config_mgr

    def __repr__(self):
        return "0.0"

    def all(self):
        print("test")

    def clone_git_repos(self):

        git_repos = self.config_mgr.git_repos

        print("\nPrepare to clone git repos:")
        tb = pt.PrettyTable()
        tb.field_names = ["src", "dst"]
        src_dst_map = []
        for git_repo in git_repos:
            src = git_repo["src"]
            dst = os.path.join(self.home, git_repo["dst"])
            src_dst_map.append((src, dst))
            tb.add_row([src, dst])

        print(tb)
        if not click.confirm("Do you want to continue?", default=False):
            return
        time.sleep(3)

        for src, dst in src_dst_map:
            print(f"clone {src} to {dst}")
            self.git_agent.clone(repo=src, dst_path=dst)

    def link_dotfiles(self):

        dotfiles = self.config_mgr.dotfiles

        print("\nPrepare to link dotfiles:")
        tb = pt.PrettyTable()
        tb.field_names = ["src", "dst"]
        src_dst_map = []
        for dotfile in dotfiles:
            src = os.path.join(self.cwd, dotfile["src"])
            dst = os.path.join(self.home, dotfile["dst"])
            src_dst_map.append((src, dst))
            tb.add_row([src, dst])

        print(tb)
        if not click.confirm("Do you want to continue?", default=False):
            return

        for src, dst in src_dst_map:
            dst_dirname = os.path.dirname(dst)
            FileUtils.create_dir(dst_dirname)
            FileUtils.delete_link(dst)
            FileUtils.delete_file(dst)
            print(f"start to link:{src} to {dst}")
            os.symlink(src, dst)

    def install_fonts(self):
        if self.system == SupportedSystems.DARWIN.value:
            return

        font_d = f"{Path.home()}/.local/share/fonts"
        font_config_d = f"{Path.home()}/.config/fontconfig/conf.d"

        FileUtils.create_dir(font_d)
        FileUtils.create_dir(font_config_d)

        urllib.request.urlretrieve(
            "https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf",
            f"{font_d}/PowerlineSymbols.otf",
        )

        SubProcess.run(shlex.split(f"fc-cache -vf {font_d}"))

        urllib.request.urlretrieve(
            "https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf",
            f"{font_config_d}/10-powerline-symbols.conf",
        )


def check_supported() -> tuple[str, str, str]:
    system = platform.system()
    distrib_name = distro.name()
    distrib_ver = distro.version()

    print(f"System is {system}")
    if system == SupportedSystems.LINUX.value:
        print(f"Linux distribution is {distrib_name}:{distrib_ver}")
        time.sleep(1)

    supported_systems = tuple(system.value for system in SupportedSystems)
    supported_lix_distributions = tuple(dist.value for dist in LinuxDistributions)

    if system not in supported_systems:
        raise NotSupportError(f"does not support {system}")

    if system != "Linux":
        return system, distrib_name, distrib_ver

    # check linux distrbutino
    if distrib_name not in supported_lix_distributions:
        raise NotSupportError(f"does not support {distrib_name}")


    return system, distrib_name, distrib_ver


@click.command(context_settings=dict(help_option_names=["-h", "--help"]))
@click.option("-a", "--all", "install_all", is_flag=True, help="install all", default=False)
@click.option(
    "-g", "--git", "clone_git_repos", is_flag=True, help="glone git repositories", default=False
)
def cli(install_all: bool, clone_git_repos: bool):

    system, distrib_name, distrib_ver = check_supported()

    installer = Installer(
        home=Path.home(),
        system=system,
        distrib_name=distrib_name,
        distrib_ver=distrib_ver,
        git_agent=GitAgent,
        config_mgr=ConfigMgr(),
    )

    installer.link_dotfiles()

    if install_all:
        installer.install_fonts()

    if install_all or clone_git_repos:
        installer.clone_git_repos()


if __name__ == "__main__":
    cli()
