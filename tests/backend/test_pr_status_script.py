"""End-to-end tests for ``scripts/pr-status.sh``.

The script shells out to ``gh pr view`` for each PR it is asked about. We
replace ``gh`` with a tiny Python stub (selected via ``GH_CMD``) so the
tests can run offline and assert deterministic output.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from collections.abc import Iterator
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = PROJECT_ROOT / "scripts" / "pr-status.sh"


def _write_stub(tmp_path: Path, fixtures: dict[int, dict]) -> Path:
    """Write a Python ``gh`` stub that replays canned JSON per PR number.

    The stub accepts ``gh pr view <NUM> --json <fields>`` invocations and
    prints the matching fixture as JSON. Any other invocation exits 2 so
    tests notice unexpected arguments.
    """

    fixtures_path = tmp_path / "fixtures.json"
    fixtures_path.write_text(
        json.dumps({str(num): payload for num, payload in fixtures.items()})
    )

    stub_path = tmp_path / "gh-stub.py"
    stub_path.write_text(
        "#!/usr/bin/env python3\n"
        "import json, os, sys\n"
        "argv = sys.argv[1:]\n"
        "if len(argv) < 3 or argv[0] != 'pr' or argv[1] != 'view':\n"
        "    sys.stderr.write(f'unexpected gh args: {argv}\\n')\n"
        "    sys.exit(2)\n"
        "number = argv[2]\n"
        "with open(os.environ['GH_STUB_FIXTURES']) as fh:\n"
        "    fixtures = json.load(fh)\n"
        "if number not in fixtures:\n"
        "    sys.stderr.write(f'no fixture for PR {number}\\n')\n"
        "    sys.exit(1)\n"
        "print(json.dumps(fixtures[number]))\n"
    )
    stub_path.chmod(0o755)

    wrapper = tmp_path / "gh-stub"
    wrapper.write_text(
        f'#!/usr/bin/env bash\nexec "{sys.executable}" "{stub_path}" "$@"\n'
    )
    wrapper.chmod(0o755)

    os.environ["GH_STUB_FIXTURES"] = str(fixtures_path)
    return wrapper


def _passing_pr(number: int = 64, title: str = "Passing PR") -> dict:
    return {
        "number": number,
        "title": title,
        "state": "OPEN",
        "url": f"https://github.com/example/repo/pull/{number}",
        "author": {"login": "alice"},
        "headRefName": "feature/x",
        "baseRefName": "main",
        "createdAt": "2026-01-05T10:00:00Z",
        "updatedAt": "2026-01-05T20:40:00Z",
        "mergeable": "MERGEABLE",
        "mergeStateStatus": "CLEAN",
        "reviewDecision": "APPROVED",
        "reviews": [
            {"state": "APPROVED", "author": {"login": "bob"}},
        ],
        "comments": [{"id": 1}, {"id": 2}, {"id": 3}],
        "statusCheckRollup": [
            {
                "name": "lint",
                "status": "COMPLETED",
                "conclusion": "SUCCESS",
            },
            {
                "name": "test",
                "status": "COMPLETED",
                "conclusion": "SUCCESS",
            },
            {
                "name": "typecheck",
                "status": "COMPLETED",
                "conclusion": "SUCCESS",
            },
            {
                "name": "build",
                "status": "COMPLETED",
                "conclusion": "SUCCESS",
            },
        ],
    }


def _failing_pr(number: int = 65) -> dict:
    payload = _passing_pr(number=number, title="Failing PR")
    payload["mergeable"] = "CONFLICTING"
    payload["reviewDecision"] = "CHANGES_REQUESTED"
    payload["statusCheckRollup"] = [
        {"name": "lint", "status": "COMPLETED", "conclusion": "SUCCESS"},
        {"name": "test", "status": "COMPLETED", "conclusion": "FAILURE"},
        {"name": "build", "status": "COMPLETED", "conclusion": "SUCCESS"},
        {"name": "type", "status": "COMPLETED", "conclusion": "SUCCESS"},
    ]
    return payload


def _pending_pr(number: int = 66) -> dict:
    payload = _passing_pr(number=number, title="Pending PR")
    payload["reviewDecision"] = ""
    payload["reviews"] = []
    payload["comments"] = [{"id": 1}, {"id": 2}]
    payload["mergeable"] = "UNKNOWN"
    payload["statusCheckRollup"] = [
        {"name": "lint", "status": "IN_PROGRESS", "conclusion": ""},
        {"name": "test", "status": "QUEUED", "conclusion": ""},
        {"name": "build", "status": "QUEUED", "conclusion": ""},
        {"name": "type", "status": "QUEUED", "conclusion": ""},
    ]
    return payload


@pytest.fixture()
def env(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Iterator[Path]:
    """Isolate cache dir and ensure the script exists before each test."""

    assert SCRIPT.exists(), f"pr-status.sh missing at {SCRIPT}"
    cache_dir = tmp_path / "cache"
    monkeypatch.setenv("PR_STATUS_CACHE_DIR", str(cache_dir))
    monkeypatch.setenv("NO_COLOR", "1")
    yield tmp_path


def _run(
    stub: Path, *args: str, stdin: str | None = None
) -> subprocess.CompletedProcess[str]:
    kwargs: dict = {
        "env": {**os.environ, "GH_CMD": str(stub)},
        "capture_output": True,
        "text": True,
        "check": False,
    }
    if stdin is None:
        kwargs["stdin"] = subprocess.DEVNULL
    else:
        kwargs["input"] = stdin
    return subprocess.run([str(SCRIPT), *args], **kwargs)


def test_script_is_executable() -> None:
    assert SCRIPT.exists(), "scripts/pr-status.sh must exist"
    assert os.access(SCRIPT, os.X_OK), "scripts/pr-status.sh must be executable"


def test_usage_on_no_args(env: Path) -> None:
    stub = _write_stub(env, {64: _passing_pr()})
    result = _run(stub)
    assert result.returncode == 3
    assert "Usage" in result.stderr or "Usage" in result.stdout


def test_help_flag(env: Path) -> None:
    stub = _write_stub(env, {64: _passing_pr()})
    result = _run(stub, "--help")
    assert result.returncode == 0
    assert "Usage" in result.stdout


def test_default_output_passing_pr(env: Path) -> None:
    stub = _write_stub(env, {64: _passing_pr(title="User Story Suggestions")})
    result = _run(stub, "64")
    assert result.returncode == 0, result.stderr
    out = result.stdout
    assert "PR #64" in out
    assert "User Story Suggestions" in out
    assert "OPEN" in out
    assert "4/4" in out
    assert "passing" in out.lower()
    assert "1 approval" in out
    assert "3 comments" in out
    assert "Mergeable" in out
    assert "YES" in out


def test_failing_pr_exit_code_and_output(env: Path) -> None:
    stub = _write_stub(env, {65: _failing_pr()})
    result = _run(stub, "65")
    assert result.returncode == 1, result.stderr
    out = result.stdout
    assert "PR #65" in out
    assert "failing" in out.lower()
    assert "1/4" in out  # 1 of 4 failing
    assert "NO" in out  # mergeable NO due to conflict


def test_pending_pr_exit_code_and_output(env: Path) -> None:
    stub = _write_stub(env, {66: _pending_pr()})
    result = _run(stub, "66")
    assert result.returncode == 2, result.stderr
    out = result.stdout
    assert "PR #66" in out
    assert "pending" in out.lower()
    assert "UNKNOWN" in out


def test_multiple_prs_aggregate_exit_codes(env: Path) -> None:
    stub = _write_stub(
        env,
        {
            64: _passing_pr(),
            65: _failing_pr(),
            66: _pending_pr(),
        },
    )
    result = _run(stub, "64", "65", "66")
    # failing wins over pending which wins over passing
    assert result.returncode == 1
    out = result.stdout
    assert "PR #64" in out
    assert "PR #65" in out
    assert "PR #66" in out


def test_pending_wins_when_no_failures(env: Path) -> None:
    stub = _write_stub(env, {64: _passing_pr(), 66: _pending_pr()})
    result = _run(stub, "64", "66")
    assert result.returncode == 2


def test_summary_flag_one_line_per_pr(env: Path) -> None:
    stub = _write_stub(env, {64: _passing_pr(title="A"), 65: _failing_pr()})
    result = _run(stub, "--summary", "64", "65")
    lines = [line for line in result.stdout.splitlines() if line.strip()]
    assert len(lines) == 2, result.stdout
    assert "#64" in lines[0]
    assert "#65" in lines[1]


def test_json_flag_emits_valid_array(env: Path) -> None:
    stub = _write_stub(env, {64: _passing_pr(), 65: _failing_pr()})
    result = _run(stub, "--json", "64", "65")
    assert result.returncode == 1, result.stderr
    data = json.loads(result.stdout)
    assert isinstance(data, list)
    assert len(data) == 2
    numbers = {entry["number"] for entry in data}
    assert numbers == {64, 65}
    pr64 = next(e for e in data if e["number"] == 64)
    assert pr64["ci"]["total"] == 4
    assert pr64["ci"]["passing"] == 4
    assert pr64["reviews"]["approvals"] == 1
    assert pr64["mergeable"] == "YES"


def test_ci_only_flag_suppresses_reviews(env: Path) -> None:
    stub = _write_stub(env, {64: _passing_pr()})
    result = _run(stub, "--ci-only", "64")
    assert result.returncode == 0
    out = result.stdout
    assert "CI" in out
    assert "approval" not in out.lower()
    assert "Mergeable" not in out


def test_reviews_only_flag_suppresses_ci(env: Path) -> None:
    stub = _write_stub(env, {64: _passing_pr()})
    result = _run(stub, "--reviews-only", "64")
    assert result.returncode == 0
    out = result.stdout
    assert "Reviews" in out or "approval" in out.lower()
    # CI rollup details should not appear
    assert "/4 checks" not in out


def test_verbose_lists_individual_checks(env: Path) -> None:
    stub = _write_stub(env, {65: _failing_pr()})
    result = _run(stub, "--verbose", "65")
    assert result.returncode == 1
    out = result.stdout
    # verbose must enumerate each check name with its result
    assert "lint" in out
    assert "test" in out
    assert "build" in out
    assert "FAILURE" in out or "fail" in out.lower()


def test_stdin_accepts_pr_numbers(env: Path) -> None:
    stub = _write_stub(env, {64: _passing_pr(), 65: _failing_pr()})
    result = _run(stub, stdin="64 65\n")
    assert result.returncode == 1, result.stderr
    assert "PR #64" in result.stdout
    assert "PR #65" in result.stdout


def test_rejects_non_numeric_pr(env: Path) -> None:
    stub = _write_stub(env, {64: _passing_pr()})
    result = _run(stub, "abc")
    assert result.returncode == 3
    assert "abc" in (result.stderr + result.stdout)


def test_cache_reuses_result_within_ttl(env: Path) -> None:
    stub = _write_stub(env, {64: _passing_pr()})
    # First run populates cache
    first = _run(stub, "64")
    assert first.returncode == 0
    # Replace stub with one that fails if invoked — cache must prevent calls
    broken = env / "gh-broken"
    broken.write_text("#!/usr/bin/env bash\nexit 77\n")
    broken.chmod(0o755)
    cached = subprocess.run(
        [str(SCRIPT), "64"],
        env={**os.environ, "GH_CMD": str(broken)},
        capture_output=True,
        text=True,
        check=False,
    )
    assert cached.returncode == 0, cached.stderr
    assert "PR #64" in cached.stdout


def test_no_cache_flag_bypasses_cache(env: Path) -> None:
    stub = _write_stub(env, {64: _passing_pr()})
    first = _run(stub, "64")
    assert first.returncode == 0
    broken = env / "gh-broken"
    broken.write_text("#!/usr/bin/env bash\nexit 77\n")
    broken.chmod(0o755)
    result = subprocess.run(
        [str(SCRIPT), "--no-cache", "64"],
        env={**os.environ, "GH_CMD": str(broken)},
        capture_output=True,
        text=True,
        check=False,
    )
    # Without cache, the broken stub should cause failure
    assert result.returncode != 0
