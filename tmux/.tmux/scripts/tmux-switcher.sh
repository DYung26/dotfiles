#!/usr/bin/env bash
# tmux-switcher.sh
#
# Level 1 (default): one compact line per repo/session. Fuzzy search
# filters by repo name.
#   Enter -> jump into that session (its current window), creating the
#            session on the `main` worktree first if it doesn't exist yet.
#   Tab   -> drill into that repo: a second fuzzy list of its exact open
#            windows plus any not-yet-opened worktrees, tagged [open]/[new].
#            Esc from here returns to the level-1 list instead of closing.
#
set -euo pipefail
PROJECTS_DIR="$HOME/Projects"

list_worktrees() { # repo -> newline list of worktree names (incl. main)
  local repo="$1"
  local wt_dir="$PROJECTS_DIR/${repo}.wt"
  [ -d "$PROJECTS_DIR/$repo" ] && echo "main"
  if [ -d "$wt_dir" ]; then
    for w in "$wt_dir"/*; do
      [ -d "$w" ] || continue
      basename "$w"
    done
  fi
}

worktree_path() { # repo name -> filesystem path
  local repo="$1" name="$2"
  if [ "$name" = "main" ] && [ -d "$PROJECTS_DIR/$repo" ]; then
    echo "$PROJECTS_DIR/$repo"
  else
    echo "$PROJECTS_DIR/${repo}.wt/${name}"
  fi
}

jump_to_window() { # repo, worktree/window name -> creates if needed, switches
  local repo="$1" name="$2"
  if tmux has-session -t "$repo" 2>/dev/null \
      && tmux list-windows -t "$repo" -F '#{window_name}' | grep -qx "$name"; then
    tmux switch-client -t "${repo}:${name}"
    return
  fi
  local path; path=$(worktree_path "$repo" "$name")
  if ! tmux has-session -t "$repo" 2>/dev/null; then
    tmux new-session -d -s "$repo" -n "$name" -c "$path" 'nvim'
  else
    tmux new-window -t "$repo" -n "$name" -c "$path" 'nvim'
  fi
  tmux switch-client -t "${repo}:${name}"
}

drill_repo() { # level 2: pick an exact window/worktree for one repo
  # returns 1 (picks nothing) on Esc, so the caller can go back to level 1
  local repo="$1"
  local open_windows
  open_windows=$(tmux list-windows -t "$repo" -F '#{window_name}' 2>/dev/null || true)
  local lines=""
  local w tag
  while IFS= read -r w; do
    [ -z "$w" ] && continue
    if echo "$open_windows" | grep -qx "$w"; then
      tag="open"
    else
      tag="new"
    fi
    lines="${lines}${w}  [${tag}]
"
  done < <(list_worktrees "$repo")

  local pick
  pick=$(printf '%s' "$lines" | sort -u | fzf --reverse --cycle \
    --header "${repo}: pick a window/worktree  (Esc: back)" | awk '{print $1}')
  if [ -z "$pick" ]; then
    return 1
  fi
  jump_to_window "$repo" "$pick"
  return 0
}

build_level1() { # one line per repo: open sessions, then not-yet-opened repos
  tmux list-sessions -F '#{session_name}' 2>/dev/null || true
  for repo_dir in "$PROJECTS_DIR"/*.wt; do
    [ -d "$repo_dir" ] || continue
    local repo
    repo=$(basename "$repo_dir" .wt)
    tmux has-session -t "$repo" 2>/dev/null && continue
    echo "${repo} (new)"
  done
}

query=""
while true; do
  result=$(build_level1 | sort -u | fzf --reverse --cycle --expect=tab \
    --query "$query" --print-query \
    --header 'Enter: jump in  |  Tab: pick exact window/worktree') || true

  query=$(printf '%s' "$result" | sed -n 1p)
  key=$(printf '%s' "$result" | sed -n 2p)
  line=$(printf '%s' "$result" | sed -n 3p)
  [ -z "$line" ] && exit 0
  repo="${line% (new)}"

  if [ "$key" = "tab" ]; then
    if drill_repo "$repo"; then
      exit 0
    else
      continue # Esc'd out of the drill-down; back to the session list, query preserved
    fi
  elif tmux has-session -t "$repo" 2>/dev/null; then
    tmux switch-client -t "$repo"
    exit 0
  else
    jump_to_window "$repo" "main"
    exit 0
  fi
done
