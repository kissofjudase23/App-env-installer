import os
import shutil
import subprocess
import tomllib
from pathlib import Path

import pytest

ASSETS = Path(__file__).resolve().parent.parent / "assets"


def run(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, timeout=60, check=False)


# These files are live config through ~/.assets; a syntax error breaks git/tmux/the prompt
def test_gitconfig_parses():
    if shutil.which("git") is None:
        pytest.skip("git is not installed")
    result = run(["git", "config", "--file", str(ASSETS / "git/gitconfig"), "--list"])
    assert result.returncode == 0, result.stderr


def test_starship_toml_parses():
    with open(ASSETS / "starship/starship.toml", "rb") as fd:
        assert tomllib.load(fd)


def test_tmux_conf_parses():
    tmux = shutil.which("tmux")
    if tmux is None:
        pytest.skip("tmux is not installed")
    # A private server socket; -n parses the file without applying it
    socket = f"assets-test-{os.getpid()}"
    conf = str(ASSETS / "tmux/tmux.conf")
    try:
        result = run(
            [tmux, "-L", socket, "-f", os.devnull, "start-server", ";", "source-file", "-n", conf]
        )
    finally:
        run([tmux, "-L", socket, "kill-server"])
    assert (result.returncode, result.stderr) == (0, ""), result.stderr
