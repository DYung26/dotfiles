#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/systemd/bin/restart-docker-containers"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/docker-restart-test.XXXXXX")"
trap 'rm -rf -- "$tmp_root"' EXIT

fake_repo="$tmp_root/repo"
fake_bin="$tmp_root/bin"
allowlist="$fake_repo/allowlist.conf"
restart_log="$tmp_root/restarts.log"

mkdir -p "$fake_repo" "$fake_bin"
: > "$restart_log"

cat > "$fake_bin/docker" <<'FAKE_DOCKER'
#!/usr/bin/env bash
set -Eeuo pipefail

case "$1" in
  ps)
    [[ "$2" == "--format" && "$3" == "{{.Names}}" ]] || exit 90
    printf '%s\n' worker postgres workspace-mcp
    ;;
  inspect)
    [[ "$2" == "--format" ]] || exit 91
    case "$4" in
      worker) printf '/worker|example/worker:latest|worker\n' ;;
      postgres) printf '/postgres|postgres:16|postgres\n' ;;
      workspace-mcp) printf '/workspace-mcp|example/workspace-mcp:latest|workspace-mcp\n' ;;
      *) exit 92 ;;
    esac
    ;;
  restart)
    printf '%s\n' "$2" >> "$RESTART_LOG"
    ;;
  *)
    exit 93
    ;;
esac
FAKE_DOCKER
chmod +x "$fake_bin/docker"

export PATH="$fake_bin:$PATH"
export DOTFILES_REPO="$fake_repo"
export DOCKER_RESTART_ALLOWLIST="$allowlist"
export RESTART_LOG="$restart_log"

cat > "$allowlist" <<'ALLOWLIST'
# Only explicitly approved application containers may be restarted.
worker
postgres
workspace-mcp
stopped
ALLOWLIST

dry_run_output="$(DRY_RUN=1 "$script")"
grep -Fq 'WOULD RESTART worker' <<< "$dry_run_output"
grep -Fq 'SKIP postgres: protected database or control-plane workload' <<< "$dry_run_output"
grep -Fq 'SKIP workspace-mcp: protected database or control-plane workload' <<< "$dry_run_output"
grep -Fq 'SKIP stopped: not running' <<< "$dry_run_output"
[[ ! -s "$restart_log" ]]

run_output="$("$script")"
grep -Fq 'Finished: restarted=1 skipped=3 failed=0' <<< "$run_output"
[[ "$(cat "$restart_log")" == 'worker' ]]

: > "$restart_log"
: > "$allowlist"
empty_output="$("$script")"
grep -Fq 'Device allowlist is empty; no containers will be restarted' <<< "$empty_output"
[[ ! -s "$restart_log" ]]

printf 'PASS: only explicitly allowlisted non-protected running containers are restarted\n'
