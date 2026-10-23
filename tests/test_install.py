from pathlib import Path

import pytest
import yaml

import install

TIGRC = install.ROOT / "assets/tig/tigrc"


@pytest.fixture
def home(tmp_path: Path) -> Path:
    path = tmp_path / "home"
    path.mkdir()
    return path


@pytest.fixture(autouse=True)
def no_side_effects(monkeypatch):
    # Tests must never shell out or hit the network
    def fail(*args, **kwargs):
        raise AssertionError(f"unexpected call: {args}")

    monkeypatch.setattr(install.subprocess, "run", fail)
    monkeypatch.setattr(install.urllib.request, "urlretrieve", fail)


def make_installer(
    tmp_path: Path, home: Path, *, dry_run: bool = False, system: str = "Darwin", **config
) -> install.Installer:
    config_path = tmp_path / "config.yaml"
    config_path.write_text(
        yaml.safe_dump({"dotfiles": [], "git_repos": [], **config}), encoding="utf-8"
    )
    return install.Installer(
        home=home,
        system=system,
        git_agent=install.GitAgent(dry_run=dry_run),
        config_mgr=install.ConfigMgr(config_path),
        assume_yes=True,
        dry_run=dry_run,
    )


def snapshot(home: Path) -> dict[str, str]:
    return {
        str(p.relative_to(home)): str(p.readlink()) if p.is_symlink() else p.read_text()
        for p in sorted(home.rglob("*"))
        if p.is_symlink() or p.is_file()
    }


def backups(home: Path, name: str) -> list[Path]:
    return list(home.glob(f"{name}.bak.*"))


def test_link_dotfiles_creates_symlink_and_parents(tmp_path, home):
    dotfiles = [{"name": "tigrc", "src": "assets/tig/tigrc", "dst": ".config/tig/tigrc"}]
    make_installer(tmp_path, home, dotfiles=dotfiles).link_dotfiles()

    dst = home / ".config/tig/tigrc"
    assert dst.is_symlink()
    assert dst.resolve() == TIGRC.resolve()


def test_link_dotfiles_backs_up_existing_file(tmp_path, home):
    (home / ".tigrc").write_text("mine")
    dotfiles = [{"name": "tigrc", "src": "assets/tig/tigrc", "dst": ".tigrc"}]
    make_installer(tmp_path, home, dotfiles=dotfiles).link_dotfiles()

    assert (home / ".tigrc").resolve() == TIGRC.resolve()
    [backup] = backups(home, ".tigrc")
    assert backup.read_text() == "mine"


def test_link_dotfiles_replaces_stale_symlink_without_backup(tmp_path, home):
    (home / ".tigrc").symlink_to(tmp_path / "elsewhere")
    dotfiles = [{"name": "tigrc", "src": "assets/tig/tigrc", "dst": ".tigrc"}]
    make_installer(tmp_path, home, dotfiles=dotfiles).link_dotfiles()

    assert (home / ".tigrc").resolve() == TIGRC.resolve()
    assert backups(home, ".tigrc") == []


def test_link_dotfiles_is_idempotent(tmp_path, home):
    dotfiles = [{"name": "tigrc", "src": "assets/tig/tigrc", "dst": ".tigrc"}]
    installer = make_installer(tmp_path, home, dotfiles=dotfiles)
    installer.link_dotfiles()
    before = snapshot(home)
    installer.link_dotfiles()

    assert snapshot(home) == before


def test_ensure_gitconfig_local_keeps_existing(tmp_path, home):
    installer = make_installer(tmp_path, home)
    installer.ensure_gitconfig_local()
    assert "[user]" in (home / ".gitconfig.local").read_text()

    (home / ".gitconfig.local").write_text("custom")
    installer.ensure_gitconfig_local()
    assert (home / ".gitconfig.local").read_text() == "custom"


def test_clone_skips_existing_repo(tmp_path, home):
    (home / "repo/.git").mkdir(parents=True)
    git_repos = [{"name": "repo", "src": "https://example.com/repo.git", "dst": "repo"}]
    make_installer(tmp_path, home, git_repos=git_repos).clone_git_repos()


def test_install_go_tools_skips_without_go(tmp_path, home, monkeypatch):
    monkeypatch.setattr(install.shutil, "which", lambda _: None)
    make_installer(tmp_path, home, go_tools=["example.com/tool@latest"]).install_go_tools()


def test_dry_run_changes_nothing(tmp_path, home):
    (home / ".tigrc").write_text("mine")
    installer = make_installer(
        tmp_path,
        home,
        dry_run=True,
        system="Linux",
        dotfiles=[
            {"name": "tigrc", "src": "assets/tig/tigrc", "dst": ".tigrc"},
            {"name": "tmux", "src": "assets/tmux/tmux.conf", "dst": ".config/tmux/tmux.conf"},
        ],
        git_repos=[{"name": "repo", "src": "https://example.com/repo.git", "dst": "repo"}],
        go_tools=["example.com/tool@latest"],
    )
    before = snapshot(home)

    installer.link_dotfiles()
    installer.ensure_gitconfig_local()
    installer.install_fonts()
    installer.clone_git_repos()
    installer.install_go_tools()

    assert snapshot(home) == before
    assert sorted(p.name for p in home.iterdir()) == [".tigrc"]
