import abc
from enum import Enum, unique
import platform
import yaml
from pathlib import Path
# from pprint import pprint as pp
import subprocess
import os
import shlex
import urllib.request


class BaseError(Exception):
    pass


class NotSupportError(BaseError):
    pass


class InstallPkgError(BaseError):
    pass


class SubProcessError(InstallPkgError):
    pass


@unique
class Systems(Enum):
    DARWIN = "Darwin"
    LINUX = "Linux"


@unique
class LinuxDistributions(Enum):
    UBUNTU = "Ubuntu"
    CENTOS = "CentOS Linux"


class SubProcess():
    @staticmethod
    def run_get_ret(cmd):
        return subprocess.run(cmd, stdout=subprocess.DEVNULL).returncode

    @staticmethod
    def run(cmd, *, shell=False, user_input=None):
        print(f"subprocess cmd: {cmd}")
        # redirect std.err to std.out
        # when set input in subprocess.run, the internal
        # stdin is subprocess.PIPE
        p = subprocess.run(cmd,
                           shell=shell,
                           input=user_input,
                           encoding="utf-8")
        p.check_returncode()


class FileUtils():
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


class PkgMgrAgent(abc.ABC):
    def check_installed(self, pkg):
        """
        Use which to check if the pkg installed
        """
        cmd = ("which", pkg)
        ret_code = SubProcess.run_get_ret(cmd)
        return True if ret_code == 0 else False

    @abc.abstractmethod
    def install(self, pkg):
        raise NotImplementedError("0.0")


class DarwinAgent(PkgMgrAgent):
    def __init__(self, update=True):
        # install homebrew
        self.brew = "brew"
        self.brew_cast = "brew cask"
        if not self.check_installed("brew"):
            print("install brew:")
            cmd = r'/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
            # \n means enter
            SubProcess.run(cmd, shell=True, user_input="\n")

        if update:
            print("update brew:")
            SubProcess.run(shlex.split(f"{self.brew} update --force --verbose"))

    def install(self, pkg_info):
        bin_name = pkg_info["bin"]
        name = pkg_info["bin"]
        pkg = pkg_info["pkg"]
        tap = pkg_info["tap"]
        cask = pkg_info["cask"]

        print(f"install name:{name}, pkg:{pkg}, tap:{tap}:")
        if bin_name and self.check_installed(bin_name):
            return

        if tap:
            SubProcess.run(shlex.split(f"{self.brew} tap {tap}"))

        pkg_mgr = self.brew
        if cask:
            pkg_mgr = self.brew_cast

        SubProcess.run(shlex.split(f"{pkg_mgr} install {pkg}"))

    def __repr__(self):
        return "DarwinAgent"


class UbuntuAgent(PkgMgrAgent):
    def __init__(self, distrib_ver):
        del distrib_ver
        self.pkg_mgr = "apt"
        SubProcess.run(shlex.split(f"{self.pkg_mgr} update -y"))
        SubProcess.run(shlex.split(f"{self.pkg_mgr} install -y software-properties-common"))
        SubProcess.run(shlex.split(f"{self.pkg_mgr} update -y"))

    def install(self, pkg_info):
        bin_name = pkg_info["bin"]
        name = pkg_info["bin"]
        pkg = pkg_info["pkg"]
        add_repo = pkg_info["add-repo"]

        print(f"install name:{name}, pkg:{pkg}:, add_repo:{add_repo}")
        if bin_name and self.check_installed(bin_name):
            return

        if add_repo:
            SubProcess.run(shlex.split(f"add-apt-repository -y {add_repo}"))

        SubProcess.run(shlex.split(f"{self.pkg_mgr} install -y {pkg}"))

    def __repr__(self):
        return "UbuntuAgent"


class CentOSAgent(PkgMgrAgent):
    def __init__(self, distrib_ver):
        self.pkg_mgr = "apt"
        if distrib_ver[0] >= '8':
            self.pkg_mgr = "dnf"

        SubProcess.run(shlex.split(f"{self.pkg_mgr} update -y"))
        SubProcess.run(shlex.split(f"{self.pkg_mgr} install -y epel-release"))

    def install(self, pkg_info):
        bin_name = pkg_info["bin"]
        name = pkg_info["bin"]
        pkg = pkg_info["pkg"]

        print(f"install name:{name}, pkg:{pkg}:")
        if bin_name and self.check_installed(bin_name):
            return

        SubProcess.run(shlex.split(f"{self.pkg_mgr} install -y {pkg}"))

    def __repr__(self):
        return "CentOSAgent"


class GitAgent():
    @classmethod
    def clone(cls, repo, dst_path, *, check=True):
        if check and FileUtils.check_and_create_dir(dst_path):
            return
        cmd = ("git", "clone", "--recurse-submodules", repo, dst_path)
        SubProcess.run(cmd)


class Installer():
    def __init__(self, *, home, git_agent, pkg_install_agent):
        self.home = home
        self.cwd = os.path.abspath(os.getcwd())
        self.git_agent = git_agent
        self.pkg_install_agent = pkg_install_agent

    def __repr__(self):
        return "0.0"

    def all(self):
        print("test")

    def pkgs(self, pkgs):
        print(f'\nstart to pkgs:')
        for pkg in pkgs:
            self.pkg_install_agent.install(pkg)

    def git_repos(self, git_repos):
        print(f'\nstart to clone git repos:')
        for git_repo in git_repos:
            src = git_repo["src"]
            dst = os.path.join(self.home, git_repo["dst"])
            print(f'"{git_repo["name"]}: src:{src}, dst:{dst}')
            self.git_agent.clone(repo=src, dst_path=dst)

    def dotfiles(self, dotfiles):
        print(f'\nstart to link dotfiles:')
        for dotfile in dotfiles:
            src = os.path.join(self.cwd, dotfile["src"])
            dst = os.path.join(self.home, dotfile["dst"])
            dst_dirname = os.path.dirname(dst)
            print(f'"{dotfile["name"]}: src:{src}, dst:{dst}')
            FileUtils.create_dir(dst_dirname)
            FileUtils.delete_link(dst)
            FileUtils.delete_file(dst)
            os.symlink(src, dst)


def get_agent(system, distrib_name, distrib_ver):
    if system == Systems.DARWIN.value:
        return DarwinAgent()
    else:
        if distrib_name == LinuxDistributions.UBUNTU.value:
            return UbuntuAgent(distrib_ver)
        else:
            return CentOSAgent(distrib_ver)


def get_pkgs(system, distrib_name, distrib_ver, config):
    if system == Systems.DARWIN.value:
        return config["darwin_pkgs"]
    else:
        if distrib_name == LinuxDistributions.UBUNTU.value:
            return config["apt_pkgs"]
        else:
            return config["dnf_pkgs"]


def check_supported(system, distrib_name):
    supported_system = tuple(system.value for system in Systems)
    supported_lix_distribution = tuple(dist.value for dist in LinuxDistributions)

    if system not in supported_system:
        raise NotSupportError(f"does not support {system} now")

    if system == "Linux":
        if distrib_name not in supported_lix_distribution:
            raise NotSupportError(f"does not support {distrib_name} now")


def install_powerline_fonts():
    font_d = f"{Path.home()}/.local/share/fonts"
    font_config_d = f"{Path.home()}/.config/fontconfig/conf.d"

    FileUtils.create_dir(font_d)
    FileUtils.create_dir(font_config_d)

    urllib.request.urlretrieve("https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf",
                               f"{font_d}/PowerlineSymbols.otf")

    SubProcess.run(shlex.split(f"fc-cache -vf {font_d}"))

    urllib.request.urlretrieve("https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf",
                               f"{font_config_d}/10-powerline-symbols.conf")


def main():
    # Darwin, Ubuntu
    system = platform.system()
    print(f"system is {system}")

    # ('Ubuntu', '18.04', 'bionic')
    # ('CentOS Linux', '8.1.1911', 'Core')
    distrib_name, distrib_ver, _ = platform.linux_distribution()
    if system == Systems.LINUX.value:
        print(f"distribution is {distrib_name}:{distrib_ver}")

    # 1. check supported platform
    check_supported(system, distrib_name)

    # 2. load config to get pkg infomation
    with open("config.yaml", "r") as fd:
        config = yaml.safe_load(fd)

    # 3. get install agent
    # Darwin or Linux Agent
    pkg_mgr_agent = get_agent(system, distrib_name, distrib_ver)
    print(f'pkg_mgr_agent is {pkg_mgr_agent}')

    pkgs = get_pkgs(system, distrib_name, distrib_ver, config)
    # pp(pkgs)
    # pp(config["dotfiles"])
    # pp(config["git_repos"])

    installer = Installer(home=Path.home(),
                          git_agent=GitAgent,
                          pkg_install_agent=pkg_mgr_agent)

    installer.pkgs(pkgs)
    installer.git_repos(config["git_repos"])
    installer.dotfiles(config["dotfiles"])

    if system != Systems.DARWIN.value:
        install_powerline_fonts()

    SubProcess.run(shlex.split("pip3 install neovim --upgrade"))
    # sudo sh -c "echo $(which zsh) >> /etc/shells"
    # SubProcess.run(cmd="chsh -s $(which zsh)", shell=True)


if __name__ == "__main__":
    main()
