#!/usr/bin/env bash
# Read-only report on this repository's WSL2 setup. It never edits files,
# starts or stops services, or shows notifications. Paste the output into a bug
# report: home paths and Windows user names are abbreviated.
set -uo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
problems=0

tidy() {
  local text=$1
  if [[ -n $HOME && $HOME != / ]]; then
    text=${text//"$HOME"/\~}
  fi
  sed -E 's#/mnt/([a-z])/Users/[^/]+#/mnt/\1/Users/<user>#g' <<<"$text"
}
line() { printf '%-5s %s\n' "$1" "$(tidy "$2")"; }
ok() { line ok "$1"; }
info() { line info "$1"; }
warn() { line warn "$1"; }
fail() { line FAIL "$1"; problems=$((problems + 1)); }
section() { printf '\n== %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

printf 'claude-code-wsl2-setup doctor (read-only)\n'

is_wsl=false
if [[ -n ${WSL_DISTRO_NAME:-} ]] || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  is_wsl=true
fi
powershell=${CLAUDE_NOTIFY_POWERSHELL:-/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe}
unit=$HOME/.config/systemd/user/wsl-screenshot-cli.service

section Environment
distro=$(sed -n 's/^PRETTY_NAME=//p' /etc/os-release 2>/dev/null | tr -d '"')
info "distro: ${distro:-unknown}"
info "kernel: $(uname -r)"
if $is_wsl; then
  ok "WSL distro: ${WSL_DISTRO_NAME:-unknown}"
  if have wsl.exe; then
    # wsl.exe prints UTF-16 unless WSL_UTF8 is set; dropping NULs handles both.
    while IFS= read -r detail; do
      [[ -n $detail ]] && info "wsl.exe: $detail"
    done < <(WSL_UTF8=1 wsl.exe --version 2>/dev/null | tr -d '\0\r')
  fi
else
  warn "not running under WSL; Windows checks are skipped"
fi
if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4) )); then
  ok "bash $BASH_VERSION"
else
  fail "bash $BASH_VERSION is older than 4.4, which the statusline needs"
fi
if have jq; then
  ok "$(jq --version 2>&1)"
else
  fail "jq not found; the statusline and Codex notification need it"
fi
if have git; then
  ok "$(git --version)"
else
  warn "git not found; the statusline cannot show branches"
fi
if have claude; then
  info "claude --version: $(claude --version 2>/dev/null | head -n 1)"
else
  warn "claude not found on PATH"
fi

section "Windows interop"
if $is_wsl; then
  if [[ -x $powershell ]]; then
    ok "PowerShell: $powershell"
  else
    warn "PowerShell not executable: $powershell"
  fi
  if [[ -n ${WSL_INTEROP:-} && -S $WSL_INTEROP ]]; then
    ok "WSL_INTEROP socket: $WSL_INTEROP"
  else
    warn "WSL_INTEROP is unset or not a socket in this shell"
  fi
else
  info "skipped"
fi

section "Installed scripts"
# Reports whether an installed copy matches the repository's; returns 1 if absent.
check_copy() {
  local name=$1 source=$repo/$2 target=$3
  if [[ ! -e $target ]]; then
    info "$name: not installed at $target"
    return 1
  fi
  if cmp -s "$source" "$target"; then
    ok "$name: matches $2"
  else
    warn "$name: $target differs from $2; reinstall it unless you customized it"
  fi
}
notify=$HOME/bin/claude-notify
if check_copy claude-notify bin/claude-notify "$notify"; then
  [[ -x $notify ]] || fail "claude-notify: $notify is not executable"
  if ! grep -q FromBase64String "$notify"; then
    fail "claude-notify: this older copy puts message text inside PowerShell string literals, where a ’ in a Codex reply can break or inject commands; reinstall bin/claude-notify"
  fi
  if $is_wsl && [[ ! -x $powershell ]]; then
    fail "claude-notify: PowerShell not found at $powershell; set CLAUDE_NOTIFY_POWERSHELL for a custom mount"
  fi
fi
helper=$HOME/bin/tmux-notify-run
if check_copy tmux-notify-run bin/tmux-notify-run "$helper"; then
  [[ -x $helper ]] || fail "tmux-notify-run: $helper is not executable"
  have tmux || fail "tmux-notify-run: tmux is not installed"
  have setsid || fail "tmux-notify-run: setsid is not installed"
fi
check_copy statusline bin/statusline-command.sh "$HOME/.claude/statusline-command.sh"

section "Claude Code settings"
settings=$HOME/.claude/settings.json
if [[ ! -f $settings ]]; then
  info "$settings not found"
elif ! have jq; then
  warn "jq missing; settings not inspected"
elif ! jq empty "$settings" 2>/dev/null; then
  fail "$settings is not valid JSON"
else
  status_command=$(jq -r '.statusLine.command? // empty' "$settings" 2>/dev/null)
  if [[ $status_command == *statusline-command.sh* ]]; then
    ok "statusLine runs statusline-command.sh"
  elif [[ -n $status_command ]]; then
    info "statusLine runs another command"
  else
    info "no statusLine configured"
  fi
  # shellcheck disable=SC2016  # $matcher is a jq variable
  notify_hooks='[.hooks.Notification[]? | (.matcher // "*") as $matcher | .hooks[]?
    | select((.command? // "") | tostring | contains("claude-notify"))
    | {matcher: $matcher, async: (.async == true)}]'
  matchers=$(jq -r "$notify_hooks | map(.matcher) | join(\", \")" "$settings" 2>/dev/null)
  blocking=$(jq -r "$notify_hooks | map(select(.async | not) | .matcher) | join(\", \")" "$settings" 2>/dev/null)
  if [[ -n $matchers ]]; then
    ok "Notification hooks call claude-notify: $matchers"
  else
    info "no Notification hooks call claude-notify"
  fi
  if [[ -n $blocking ]]; then
    fail "claude-notify hooks without \"async\": true block Claude Code while the balloon is open: $blocking"
  fi
  screenshot_events=$(jq -r '[(.hooks? // {}) | to_entries[] | .key as $event | .value[]? | .hooks[]?
    | select((.command? // "") | tostring | contains("wsl-screenshot-cli")) | $event]
    | unique | join(", ")' "$settings" 2>/dev/null)
  if [[ -n $screenshot_events && -f $unit ]]; then
    fail "Claude hooks run wsl-screenshot-cli ($screenshot_events) while the systemd service owns it; remove those hooks"
  elif [[ -n $screenshot_events ]]; then
    warn "Claude hooks run wsl-screenshot-cli ($screenshot_events); this setup uses the systemd service instead"
  fi
  lsp=$(jq -r '[(.enabledPlugins? // {}) | to_entries[] | select(.value == true and (.key | test("-lsp@")))
    | .key | sub("@.*"; "")] | join(", ")' "$settings" 2>/dev/null)
  if [[ -n $lsp ]]; then
    info "LSP plugins enabled: $lsp"
  else
    info "no LSP plugins enabled"
  fi
fi
keybindings=$HOME/.claude/keybindings.json
if [[ -f $keybindings ]] && have jq; then
  if ! jq empty "$keybindings" 2>/dev/null; then
    fail "$keybindings is not valid JSON"
  elif jq -e 'type == "object" and (.bindings | type) == "array"' "$keybindings" >/dev/null 2>&1; then
    ok "keybindings.json has a bindings array"
  else
    fail "$keybindings must be an object with a \"bindings\" array; a bare array is ignored"
  fi
fi

section "Screenshot paste"
if $is_wsl; then
  if have wsl-screenshot-cli; then
    ok "wsl-screenshot-cli: $(command -v wsl-screenshot-cli)"
  elif [[ -x $HOME/.local/bin/wsl-screenshot-cli ]]; then
    warn "wsl-screenshot-cli is installed, but ~/.local/bin is not on PATH"
  else
    info "wsl-screenshot-cli not installed"
  fi
  if [[ -f $unit ]]; then
    ok "service unit: $unit"
    socket=$(sed -n 's/^Environment=WSL_INTEROP=//p' "$unit" | tail -n 1)
    if [[ -n $socket && ! -S $socket ]]; then
      warn "the unit's WSL_INTEROP socket does not exist: $socket"
    fi
    if [[ -z ${XDG_RUNTIME_DIR:-} ]] || ! have systemctl; then
      warn "cannot query the systemd user manager from this shell"
    else
      enabled=$(systemctl --user is-enabled wsl-screenshot-cli.service 2>/dev/null)
      active=$(systemctl --user is-active wsl-screenshot-cli.service 2>/dev/null)
      if [[ $enabled == enabled && $active == active ]]; then
        ok "service is enabled and active"
      else
        fail "service is ${enabled:-unknown} and ${active:-unknown}; see image-paste.md"
      fi
    fi
  else
    info "service unit not installed"
  fi
  for rc in .bashrc .bash_profile .profile .zshrc .zprofile; do
    [[ -f $HOME/$rc ]] || continue
    grep -Eq '^[^#]*wsl-screenshot-cli[[:space:]]+start' "$HOME/$rc" || continue
    if [[ -f $unit ]]; then
      fail "$HOME/$rc starts wsl-screenshot-cli; remove it so the systemd service is the only owner"
    else
      warn "$HOME/$rc starts wsl-screenshot-cli; this setup uses the systemd service instead"
    fi
  done
else
  info "skipped"
fi

section Codex
codex_config=$HOME/.codex/config.toml
if [[ -f $codex_config ]]; then
  notify_line=$(grep -nE '^[[:space:]]*notify[[:space:]]*=' "$codex_config" | head -n 1 | cut -d: -f1)
  table_line=$(grep -nE '^[[:space:]]*\[\[?[^]]+\]\]?[[:space:]]*(#.*)?$' "$codex_config" | head -n 1 | cut -d: -f1)
  if [[ -z $notify_line ]]; then
    info "no top-level notify command"
  elif [[ -n $table_line ]] && (( table_line < notify_line )); then
    fail "notify (line $notify_line) follows the table header on line $table_line, so it is not a top-level key"
  elif grep -q claude-notify "$codex_config"; then
    ok "notify calls claude-notify"
  else
    info "notify runs another command"
  fi
else
  info "$codex_config not found"
fi

section Browser
if $is_wsl; then
  if [[ -z ${BROWSER:-} ]]; then
    info "BROWSER is not set"
  elif [[ -x $BROWSER ]] || have "$BROWSER"; then
    ok "BROWSER: $BROWSER"
  else
    fail "BROWSER is not executable: $BROWSER"
  fi
  if have xdg-mime; then
    handler=$(xdg-mime query default x-scheme-handler/https 2>/dev/null)
    info "https handler: ${handler:-none}"
  fi
else
  info "skipped"
fi

section "Language servers"
for server in typescript-language-server pyright-langserver gopls rust-analyzer; do
  if have "$server"; then
    info "$server: $(command -v "$server")"
  else
    info "$server: not found"
  fi
done

printf '\n'
if (( problems > 0 )); then
  printf '%d problem(s) found.\n' "$problems"
  exit 1
fi
printf 'No problems found. Windows behavior still needs the manual checks in maintenance.md.\n'
