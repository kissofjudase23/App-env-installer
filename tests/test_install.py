import hashlib
import io
import json
import re
import tarfile
import tempfile
from pathlib import Path

import pytest
import yaml
from click.testing import CliRunner

import install

TIGRC = install.ROOT / "assets/tig/tigrc"
GITCONFIG = install.ROOT / "assets/git/gitconfig"
GITCONFIG_STUB = {"src": "assets/git/gitconfig", "dst": ".gitconfig", "stub": "gitconfig"}


def can_symlink() -> bool:
    with tempfile.TemporaryDirectory() as tmp:
        try:
            (Path(tmp) / "link").symlink_to(tmp)
        except OSError:
            return False
    return True


# Windows needs Developer Mode or admin for symlinks; CI runners have it
requires_symlinks = pytest.mark.skipif(not can_symlink(), reason="cannot create symlinks")


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
    monkeypatch.setattr(install, "register_windows_font", fail)
    monkeypatch.setattr(install, "windows_documents", fail)
    monkeypatch.setattr(install, "is_wsl", lambda: False)


def base_dirs(home: Path) -> dict[str, Path]:
    return {"home": home, "documents": home / "Documents", "local_app_data": home / "AppData/Local"}


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
        base_dirs=base_dirs(home),
        assume_yes=True,
        dry_run=dry_run,
    )


@pytest.fixture
def commands(monkeypatch) -> list[list[str]]:
    recorded: list[list[str]] = []
    monkeypatch.setattr(install.subprocess, "run", lambda cmd, **_: recorded.append(cmd))
    return recorded


def snapshot(home: Path) -> dict[str, str]:
    return {
        str(p.relative_to(home)): str(p.readlink()) if p.is_symlink() else p.read_text()
        for p in sorted(home.rglob("*"))
        if p.is_symlink() or p.is_file()
    }


def backups(home: Path, name: str) -> list[Path]:
    return list(home.glob(f"{name}.bak.*"))


@requires_symlinks
def test_link_dotfiles_creates_symlink_and_parents(tmp_path, home):
    dotfiles = [{"name": "tigrc", "src": "assets/tig/tigrc", "dst": ".config/tig/tigrc"}]
    make_installer(tmp_path, home, dotfiles=dotfiles).link_dotfiles()

    dst = home / ".config/tig/tigrc"
    assert dst.is_symlink()
    assert dst.resolve() == TIGRC.resolve()


@requires_symlinks
def test_link_dotfiles_backs_up_existing_file(tmp_path, home):
    (home / ".tigrc").write_text("mine")
    dotfiles = [{"name": "tigrc", "src": "assets/tig/tigrc", "dst": ".tigrc"}]
    make_installer(tmp_path, home, dotfiles=dotfiles).link_dotfiles()

    assert (home / ".tigrc").resolve() == TIGRC.resolve()
    [backup] = backups(home, ".tigrc")
    assert backup.read_text() == "mine"


@requires_symlinks
def test_link_dotfiles_replaces_stale_symlink_without_backup(tmp_path, home):
    (home / ".tigrc").symlink_to(tmp_path / "elsewhere")
    dotfiles = [{"name": "tigrc", "src": "assets/tig/tigrc", "dst": ".tigrc"}]
    make_installer(tmp_path, home, dotfiles=dotfiles).link_dotfiles()

    assert (home / ".tigrc").resolve() == TIGRC.resolve()
    assert backups(home, ".tigrc") == []


@requires_symlinks
def test_link_dotfiles_is_idempotent(tmp_path, home):
    dotfiles = [{"name": "tigrc", "src": "assets/tig/tigrc", "dst": ".tigrc"}]
    installer = make_installer(tmp_path, home, dotfiles=dotfiles)
    installer.link_dotfiles()
    before = snapshot(home)
    installer.link_dotfiles()

    assert snapshot(home) == before


@requires_symlinks
def test_link_dotfiles_backs_up_existing_directory(tmp_path, home):
    (home / ".assets").mkdir()
    (home / ".assets/mine").write_text("mine")
    dotfiles = [{"name": "assets", "src": "assets", "dst": ".assets"}]
    make_installer(tmp_path, home, dotfiles=dotfiles).link_dotfiles()

    assert (home / ".assets").resolve() == (install.ROOT / "assets").resolve()
    [backup] = backups(home, ".assets")
    assert (backup / "mine").read_text() == "mine"


def test_link_dotfiles_writes_gitconfig_stub(tmp_path, home):
    make_installer(tmp_path, home, system="Windows", dotfiles=[GITCONFIG_STUB]).link_dotfiles()

    dst = home / ".gitconfig"
    assert not dst.is_symlink()
    assert dst.read_bytes().decode() == (
        f"# Managed by App-env-installer; edit {GITCONFIG.as_posix()} instead\n"
        f'[include]\n    path = "{GITCONFIG.as_posix()}"\n'
    )


def test_powershell_stub_quotes_path():
    src = Path("C:/it's here/profile.ps1")
    quoted = str(src).replace("'", "''")
    assert install.STUBS["powershell"](src).splitlines()[-1] == f". '{quoted}'"


def test_link_dotfiles_stub_uses_base_dir(tmp_path, home):
    profile = {
        "src": "assets/shell/profile.ps1",
        "dst": "PowerShell/profile.ps1",
        "base": "documents",
        "stub": "powershell",
    }
    make_installer(tmp_path, home, system="Windows", dotfiles=[profile]).link_dotfiles()

    content = (home / "Documents/PowerShell/profile.ps1").read_text()
    assert content.endswith(f". '{install.ROOT / 'assets/shell/profile.ps1'}'\n")


def test_link_dotfiles_stub_is_idempotent(tmp_path, home):
    installer = make_installer(tmp_path, home, system="Windows", dotfiles=[GITCONFIG_STUB])
    installer.link_dotfiles()
    before = snapshot(home)
    installer.link_dotfiles()

    assert snapshot(home) == before
    assert backups(home, ".gitconfig") == []


def test_link_dotfiles_stub_backs_up_different_file(tmp_path, home):
    (home / ".gitconfig").write_text("mine")
    make_installer(tmp_path, home, system="Windows", dotfiles=[GITCONFIG_STUB]).link_dotfiles()

    assert "[include]" in (home / ".gitconfig").read_text()
    [backup] = backups(home, ".gitconfig")
    assert backup.read_text() == "mine"


@requires_symlinks
def test_link_dotfiles_stub_replaces_symlink(tmp_path, home):
    (home / ".gitconfig").symlink_to(GITCONFIG)
    make_installer(tmp_path, home, system="Windows", dotfiles=[GITCONFIG_STUB]).link_dotfiles()

    assert not (home / ".gitconfig").is_symlink()
    assert "[include]" in (home / ".gitconfig").read_text()
    assert GITCONFIG.read_text().startswith("[core]")


def test_link_dotfiles_filters_by_os(tmp_path, home):
    dotfiles = [
        {"src": "assets/tig/tigrc", "dst": ".tigrc", "os": ["darwin", "linux"]},
        {**GITCONFIG_STUB, "os": ["windows"]},
    ]
    git_repos = [{"src": "https://example.com/r.git", "dst": "r", "os": ["linux"]}]
    installer = make_installer(
        tmp_path, home, system="Windows", dotfiles=dotfiles, git_repos=git_repos
    )
    installer.link_dotfiles()
    installer.clone_git_repos()

    assert sorted(p.name for p in home.iterdir()) == [".gitconfig"]


def test_link_dotfiles_explains_missing_symlink_privilege(tmp_path, home, monkeypatch):
    # OSError only takes a winerror argument on Windows
    class PrivilegeNotHeld(OSError):
        winerror = property(lambda self: install.ERROR_PRIVILEGE_NOT_HELD)

    def symlink_to(self, target):
        raise PrivilegeNotHeld("privilege not held")

    monkeypatch.setattr(install.Path, "symlink_to", symlink_to)
    dotfiles = [{"src": "assets/tig/tigrc", "dst": ".tigrc"}]
    with pytest.raises(install.InstallerError, match="give the entry a stub"):
        make_installer(tmp_path, home, system="Windows", dotfiles=dotfiles).link_dotfiles()


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
        ({"dotfiles": [{**GITCONFIG_STUB, "os": ["beos"]}]}, "os must be a non-empty list"),
        ({"dotfiles": [{**GITCONFIG_STUB, "os": []}]}, "os must be a non-empty list"),
        ({"dotfiles": [{**GITCONFIG_STUB, "base": "desktop"}]}, "base must be one of"),
        ({"dotfiles": [{**GITCONFIG_STUB, "stub": "zshrc"}]}, "stub must be a dotfile"),
        (
            {"git_repos": [{"src": "https://example.com/r.git", "dst": "r", "stub": "gitconfig"}]},
            "stub must be a dotfile",
        ),
        (
            {
                "dotfiles": [
                    {"src": "assets/git/gitconfig", "dst": ".gitconfig", "os": ["linux"]},
                    {**GITCONFIG_STUB, "os": ["linux", "windows"]},
                ]
            },
            "duplicate dst: .gitconfig",
        ),
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


def test_repo_config_is_valid():
    config = install.ConfigMgr()
    assert config.dotfiles
    assert config.git_repos


def test_config_allows_same_dst_for_disjoint_os(tmp_path):
    dotfiles = [
        {"src": "assets/git/gitconfig", "dst": ".gitconfig", "os": ["darwin", "linux"]},
        {**GITCONFIG_STUB, "os": ["windows"]},
    ]
    assert len(load_config(tmp_path, {"dotfiles": dotfiles}).dotfiles) == 2


def test_repo_config_windows_uses_only_stubs(home):
    installer = install.Installer(
        home=home,
        system="Windows",
        git_agent=install.GitAgent(),
        config_mgr=install.ConfigMgr(),
        base_dirs=base_dirs(home),
    )
    entries = installer._entries("dotfiles")
    assert sorted(e["name"] for e in entries) == ["gitconfig_stub", "powershell_profile"]
    assert all("stub" in e for e in entries)
    assert installer._entries("git_repos") == []


def test_docs_dotfiles_table_matches_config():
    doc = (install.ROOT / "docs" / "configuration.md").read_text(encoding="utf-8")
    section = doc.split("## Dotfiles Linked", 1)[1].split("\n## ", 1)[0]
    rows = re.findall(r"^\| `([^`]+)`\s*\| `([^`]+)`\s*\| ([a-z, ]+?)\s*\|$", section, re.MULTILINE)
    prefixes = {"home": "~/", "documents": "Documents/"}
    expected = [
        (f["src"], prefixes[f.get("base", "home")] + f["dst"], ", ".join(f["os"]))
        for f in install.ConfigMgr().dotfiles
    ]
    assert sorted((src.rstrip("/"), dst, os) for src, dst, os in rows) == sorted(expected)


def test_clone_git_repos_runs_git_clone(tmp_path, home, commands):
    git_repos = [{"name": "repo", "src": "https://example.com/repo.git", "dst": "src/repo"}]
    make_installer(tmp_path, home, git_repos=git_repos).clone_git_repos()

    dst = str(home / "src/repo")
    assert commands == [["git", "clone", "--recurse-submodules", git_repos[0]["src"], dst]]
    assert (home / "src").is_dir()


def test_clone_skips_existing_repo(tmp_path, home):
    (home / "repo/.git").mkdir(parents=True)
    git_repos = [{"name": "repo", "src": "https://example.com/repo.git", "dst": "repo"}]
    make_installer(tmp_path, home, git_repos=git_repos).clone_git_repos()


def test_install_go_tools_runs_go_install(tmp_path, home, monkeypatch, commands):
    monkeypatch.setattr(install.shutil, "which", lambda _: "/usr/bin/go")
    tools = ["example.com/a@latest", "example.com/b@v1"]
    make_installer(tmp_path, home, go_tools=tools).install_go_tools()

    assert commands == [["/usr/bin/go", "install", tool] for tool in tools]


def test_install_go_tools_skips_without_go(tmp_path, home, monkeypatch):
    monkeypatch.setattr(install.shutil, "which", lambda _: None)
    make_installer(tmp_path, home, go_tools=["example.com/tool@latest"]).install_go_tools()


@pytest.fixture
def cli_home(home, monkeypatch) -> Path:
    monkeypatch.setattr(install.Path, "home", lambda: home)
    monkeypatch.setattr(install, "check_supported", lambda: "Darwin")
    return home


@requires_symlinks
def test_cli_links_dotfiles_by_default(cli_home):
    result = CliRunner().invoke(install.cli, ["-y"])

    assert result.exit_code == 0, result.output
    assert (cli_home / ".tigrc").resolve() == TIGRC.resolve()
    assert (cli_home / ".gitconfig.local").is_file()
    assert not (cli_home / ".oh-my-zsh").exists()


def test_cli_dry_run_all_changes_nothing(cli_home):
    result = CliRunner().invoke(install.cli, ["-a", "-y", "--dry-run"])

    assert result.exit_code == 0, result.output
    assert "git clone" in result.output
    assert list(cli_home.iterdir()) == []


def test_cli_reports_errors_with_exit_code(cli_home, monkeypatch):
    def unsupported():
        raise install.NotSupportError("does not support Plan9")

    monkeypatch.setattr(install, "check_supported", unsupported)
    result = CliRunner().invoke(install.cli, ["-y"])

    assert result.exit_code == 1
    assert "error: does not support Plan9" in result.output


@pytest.mark.parametrize(
    ("env", "url", "auth"),
    [
        ({"GH_TOKEN": "t0k"}, install.NERD_FONTS_RELEASE_API, "Bearer t0k"),
        ({"GITHUB_TOKEN": "t1k", "GH_TOKEN": "t0k"}, install.NERD_FONTS_RELEASE_API, "Bearer t1k"),
        ({"GH_TOKEN": "t0k"}, "https://github.com/o/r/releases/download/v1/a.tar.xz", None),
        ({}, install.NERD_FONTS_RELEASE_API, None),
    ],
)
def test_fetch_sends_token_only_to_github_api(monkeypatch, env, url, auth):
    requests = []

    def urlopen(req, timeout):
        requests.append(req)
        return io.BytesIO(b"ok")

    monkeypatch.setattr(install.urllib.request, "urlopen", urlopen)
    for name in ("GITHUB_TOKEN", "GH_TOKEN"):
        monkeypatch.delenv(name, raising=False)
    for name, value in env.items():
        monkeypatch.setenv(name, value)

    assert install.fetch(url) == b"ok"
    [req] = requests
    assert req.get_header("Authorization") == auth
    # never forwarded to a redirect target
    assert "Authorization" not in req.headers


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


def test_install_fonts_registers_windows_fonts(tmp_path, home, nerd_fonts_release, monkeypatch):
    archives, _, commands = nerd_fonts_release
    archives["Meslo.tar.xz"] = make_font_archive({"A.ttf": b"font", "B.ttf": b"font"})
    registered: list[Path] = []
    monkeypatch.setattr(install, "register_windows_font", registered.append)

    make_installer(tmp_path, home, system="Windows", nerd_fonts=["Meslo"]).install_fonts()

    font_dir = home / "AppData/Local/Microsoft/Windows/Fonts/NerdFonts/Meslo"
    assert registered == [font_dir / "A.ttf", font_dir / "B.ttf"]
    assert commands == []


def test_install_fonts_skips_wsl(tmp_path, home, nerd_fonts_release, monkeypatch):
    _, fetched, commands = nerd_fonts_release
    monkeypatch.setattr(install, "is_wsl", lambda: True)

    make_installer(tmp_path, home, system="Linux", nerd_fonts=["Meslo"]).install_fonts()

    assert (fetched, commands) == ([], [])


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


def test_install_fonts_rejects_missing_digest(tmp_path, home, nerd_fonts_release, monkeypatch):
    _, fetched, _ = nerd_fonts_release
    assets = {"Meslo.tar.xz": ("https://example.com/Meslo.tar.xz", "")}
    monkeypatch.setattr(install.Installer, "_nerd_font_assets", staticmethod(lambda: assets))

    with pytest.raises(install.InstallerError, match="no sha256 digest for Meslo.tar.xz"):
        make_installer(tmp_path, home, system="Linux", nerd_fonts=["Meslo"]).install_fonts()
    assert fetched == []


def os_release_error():
    raise FileNotFoundError("/etc/os-release")


@pytest.mark.parametrize(
    ("system", "os_release", "error"),
    [
        ("Darwin", None, None),
        ("Linux", lambda: {"ID": "ubuntu", "VERSION_ID": "24.04"}, None),
        ("Linux", lambda: {"ID": "fedora"}, "does not support fedora"),
        ("Linux", os_release_error, "cannot determine Linux distribution"),
        ("Windows", None, None),
        ("Plan9", None, "does not support Plan9"),
    ],
)
def test_check_supported(monkeypatch, system, os_release, error):
    monkeypatch.setattr(install.platform, "system", lambda: system)
    monkeypatch.setattr(install.platform, "freedesktop_os_release", os_release)
    if error is None:
        assert install.check_supported() == system
    else:
        with pytest.raises(install.NotSupportError, match=error):
            install.check_supported()


@pytest.mark.parametrize("system", ["Linux", "Windows"])
def test_dry_run_changes_nothing(tmp_path, home, system):
    (home / ".tigrc").write_text("mine")
    installer = make_installer(
        tmp_path,
        home,
        dry_run=True,
        system=system,
        dotfiles=[
            {"name": "tigrc", "src": "assets/tig/tigrc", "dst": ".tigrc"},
            {"name": "tmux", "src": "assets/tmux/tmux.conf", "dst": ".config/tmux/tmux.conf"},
            {**GITCONFIG_STUB, "dst": "PowerShell/profile.ps1", "base": "documents"},
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
