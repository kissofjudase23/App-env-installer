import hashlib
import io
import json
import tarfile
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
    monkeypatch.setattr(install.urllib.request, "urlopen", fail)


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


def load_config(tmp_path: Path, config) -> install.ConfigMgr:
    path = tmp_path / "config.yaml"
    path.write_text(config if isinstance(config, str) else yaml.safe_dump(config), encoding="utf-8")
    return install.ConfigMgr(path)


def test_config_defaults_missing_lists_to_empty(tmp_path):
    config = load_config(tmp_path, "nerd_fonts:\n")
    assert config.dotfiles == config.git_repos == config.go_tools == config.nerd_fonts == []


@pytest.mark.parametrize(
    ("config", "error"),
    [
        ("dotfiles: [", "cannot parse"),
        ("- a\n", "top level must be a mapping"),
        ({"dotfile": []}, "unknown keys"),
        ({"go_tools": "gopls"}, "go_tools must be a list"),
        ({"dotfiles": [{"src": "assets/tig/tigrc"}]}, "needs string src and dst"),
        ({"dotfiles": [{"src": "assets/nope", "dst": ".nope"}]}, "dotfile src not found"),
        ({"git_repos": [{"src": "https://example.com/r.git", "dst": "/tmp/r"}]}, "inside \\$HOME"),
        ({"git_repos": [{"src": "https://example.com/r.git", "dst": "a/../../r"}]}, "inside"),
        ({"dotfiles": [{"src": "assets", "dst": "."}]}, "inside \\$HOME"),
        ({"nerd_fonts": [{"name": "Meslo"}]}, "nerd_fonts entries must be strings"),
        (
            {
                "dotfiles": [{"src": "assets/tig/tigrc", "dst": ".tigrc"}],
                "git_repos": [{"src": "https://example.com/r.git", "dst": "./.tigrc"}],
            },
            "duplicate dst: .tigrc",
        ),
    ],
)
def test_config_rejects_invalid(tmp_path, config, error):
    with pytest.raises(install.InstallerError, match=error):
        load_config(tmp_path, config)


def test_clone_skips_existing_repo(tmp_path, home):
    (home / "repo/.git").mkdir(parents=True)
    git_repos = [{"name": "repo", "src": "https://example.com/repo.git", "dst": "repo"}]
    make_installer(tmp_path, home, git_repos=git_repos).clone_git_repos()


def test_install_go_tools_skips_without_go(tmp_path, home, monkeypatch):
    monkeypatch.setattr(install.shutil, "which", lambda _: None)
    make_installer(tmp_path, home, go_tools=["example.com/tool@latest"]).install_go_tools()


def make_font_archive(files: dict[str, bytes]) -> bytes:
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:xz") as tar:
        for name, data in files.items():
            info = tarfile.TarInfo(name)
            info.size = len(data)
            tar.addfile(info, io.BytesIO(data))
    return buf.getvalue()


@pytest.fixture
def nerd_fonts_release(monkeypatch):
    """Serve a fake nerd-fonts release; returns (archives, fetched urls, run commands)."""
    archives: dict[str, bytes] = {}
    fetched: list[str] = []
    commands: list[list[str]] = []

    def fetch(url):
        fetched.append(url)
        if url == install.NERD_FONTS_RELEASE_API:
            assets = [
                {
                    "name": name,
                    "browser_download_url": f"https://example.com/{name}",
                    "digest": f"sha256:{hashlib.sha256(data).hexdigest()}",
                }
                for name, data in archives.items()
            ]
            return json.dumps({"tag_name": "v0.0.0", "assets": assets}).encode()
        return archives[url.rsplit("/", 1)[1]]

    monkeypatch.setattr(install, "fetch", fetch)
    monkeypatch.setattr(install.subprocess, "run", lambda cmd, **_: commands.append(cmd))
    return archives, fetched, commands


def test_install_fonts_extracts_ttf_only(tmp_path, home, nerd_fonts_release):
    archives, _, commands = nerd_fonts_release
    archives["Meslo.tar.xz"] = make_font_archive({"A.ttf": b"font", "LICENSE.txt": b"text"})

    make_installer(tmp_path, home, system="Linux", nerd_fonts=["Meslo"]).install_fonts()

    font_dir = home / ".local/share/fonts/NerdFonts"
    assert sorted(p.name for p in (font_dir / "Meslo").iterdir()) == ["A.ttf"]
    assert sorted(p.name for p in font_dir.iterdir()) == ["Meslo"]
    assert commands == [["fc-cache", "-f", str(font_dir)]]


def test_install_fonts_skips_installed(tmp_path, home, nerd_fonts_release):
    _, fetched, commands = nerd_fonts_release
    font = home / ".local/share/fonts/NerdFonts/Meslo/A.ttf"
    font.parent.mkdir(parents=True)
    font.write_bytes(b"font")

    make_installer(tmp_path, home, system="Linux", nerd_fonts=["Meslo"]).install_fonts()

    assert fetched == []
    assert commands == []


def test_install_fonts_rejects_digest_mismatch(tmp_path, home, nerd_fonts_release, monkeypatch):
    archives, _, _ = nerd_fonts_release
    archives["Meslo.tar.xz"] = make_font_archive({"A.ttf": b"font"})
    fake_fetch = install.fetch
    monkeypatch.setattr(
        install, "fetch", lambda url: b"tampered" if url.endswith(".xz") else fake_fetch(url)
    )

    with pytest.raises(install.InstallerError, match="sha256 mismatch"):
        make_installer(tmp_path, home, system="Linux", nerd_fonts=["Meslo"]).install_fonts()
    assert not (home / ".local/share/fonts").exists()


def test_install_fonts_rejects_path_traversal(tmp_path, home, nerd_fonts_release):
    archives, _, _ = nerd_fonts_release
    archives["Meslo.tar.xz"] = make_font_archive({"../../evil.ttf": b"font"})

    with pytest.raises(install.InstallerError, match="cannot extract"):
        make_installer(tmp_path, home, system="Linux", nerd_fonts=["Meslo"]).install_fonts()
    assert not (home / ".local/share/fonts/NerdFonts/Meslo").exists()
    assert list(home.parent.rglob("evil.ttf")) == []


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
        nerd_fonts=["Meslo"],
    )
    before = snapshot(home)

    installer.link_dotfiles()
    installer.ensure_gitconfig_local()
    installer.install_fonts()
    installer.clone_git_repos()
    installer.install_go_tools()

    assert snapshot(home) == before
    assert sorted(p.name for p in home.iterdir()) == [".tigrc"]
