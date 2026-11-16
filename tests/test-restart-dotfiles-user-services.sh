#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/systemd/bin/restart-dotfiles-user-services"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-restart-test.XXXXXX")"
trap 'rm -rf -- "$tmp_root"' EXIT

fake_home="$tmp_root/home"
fake_repo="$tmp_root/repo"
fake_bin="$tmp_root/bin"
allowlist="$tmp_root/allowlist.conf"
restart_log="$tmp_root/restarts.log"

mkdir -p "$fake_home/.config/systemd/user" "$fake_repo/systemd/.config/systemd/user" "$fake_bin"
: > "$restart_log"

for unit in oneshot.service daemon.service; do
  : > "$fake_repo/systemd/.config/systemd/user/$unit"
  ln -s "$fake_repo/systemd/.config/systemd/user/$unit" "$fake_home/.config/systemd/user/$unit"
done

printf '%s\n' '# test allowlist' oneshot.service daemon.service > "$allowlist"

cat > "$fake_bin/systemctl" <<'FAKE_SYSTEMCTL'
#!/usr/bin/env bash
set -Eeuo pipefail
[[ "$1" == "--user" ]] || exit 90
shift

case "$1" in
  is-active)
    shift
    [[ "$1" == "--quiet" ]] && shift
    case "$1" in
      oneshot.service|daemon.service) exit 0 ;;
      *) exit 3 ;;
    esac
    ;;
  show)
    shift
    [[ "$1" == "--property=Type" ]] && shift
    [[ "$1" == "--value" ]] && shift
    case "$1" in
      oneshot.service) printf 'oneshot\n' ;;
      daemon.service) printf 'simple\n' ;;
      *) exit 4 ;;
    esac
    ;;
  restart)
    printf '%s\n' "$2" >> "$RESTART_LOG"
    exit 0
    ;;
  *)
    exit 91
    ;;
esac
FAKE_SYSTEMCTL
chmod +x "$fake_bin/systemctl"

export HOME="$fake_home"
export PATH="$fake_bin:$PATH"
export DOTFILES_REPO="$fake_repo"
export DOTFILES_RESTART_ALLOWLIST="$allowlist"
export RESTART_LOG="$restart_log"

output="$("$script")"

grep -Fq 'SKIP oneshot.service: Type=oneshot' <<< "$output"
grep -Fq 'Restarting daemon.service' <<< "$output"
[[ "$(cat "$restart_log")" == 'daemon.service' ]]
grep -Fq 'Finished: restarted=1 skipped=1 failed=0' <<< "$output"

printf 'PASS: one-shot units are skipped and active daemons are restarted\n'
