#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/systemd/bin/mt5-maximize-window"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/mt5-maximize-test.XXXXXX")"
trap 'rm -rf -- "$tmp_root"' EXIT

fake_bin="$tmp_root/bin"
wmctrl_log="$tmp_root/wmctrl.log"
mkdir -p "$fake_bin"

cat > "$fake_bin/wmctrl" <<'FAKE_WMCTRL'
#!/usr/bin/env bash
set -Eeuo pipefail
case "$1" in
  -lx)
    printf '%s\n' \
      '0x02600001  0 terminal64.exe.terminal64.exe host Exness-MT5Trial9: Demo Account' \
      '0x02400001  0 metaeditor64.exe.metaeditor64.exe host MetaEditor'
    ;;
  -i)
    printf '%s\n' "$*" >> "$WMCTRL_LOG"
    ;;
  *)
    exit 90
    ;;
esac
FAKE_WMCTRL
chmod +x "$fake_bin/wmctrl"

PATH="$fake_bin:$PATH" WMCTRL_LOG="$wmctrl_log" "$script"

grep -Fx -- '-i -r 0x02600001 -b add,maximized_vert,maximized_horz' "$wmctrl_log"
if grep -q '0x02400001' "$wmctrl_log"; then
  echo 'FAIL: MetaEditor window was selected' >&2
  exit 1
fi

echo 'PASS: selected terminal64.exe by WM_CLASS and ignored MetaEditor'
