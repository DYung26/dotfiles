#!/usr/bin/env bash
# tmux-switcher.sh
#
# Level 1 (default): one compact line per repo. Fuzzy search filters by
# repo name. A repo's tmux session is named after the repo itself unless
# session-names.conf maps it to a different, already-existing session name
# (see session_name_for_repo).
#   Enter -> jump into that session (its current window), creating the
#            session on the repo's default-branch worktree first if it
#            doesn't exist yet.
#   Tab   -> drill into that repo: a second fuzzy list of its exact open
#            windows plus any not-yet-opened worktrees, tagged [open]/[new].
#            Esc from here returns to the level-1 list instead of closing.
#
# Windows only ever correspond to an actual worktree path: the repo's
# primary checkout (named after its real default branch, e.g. main/develop)
# if that path exists, plus one per directory under <repo>.wt/. A branch
# with no worktree never gets a window.
#
set -euo pipefail
PROJECTS_DIR="$HOME/Projects"
SESSION_NAMES_CONF="$HOME/Projects/dotfiles/tmux/.tmux/session-names.conf"

default_branch_window_name() { # repo -> window name for the primary checkout, or empty if none
  local repo="$1"
  local repo_path="$PROJECTS_DIR/$repo"
  [ -d "$repo_path/.git" ] || [ -f "$repo_path/.git" ] || return 0
  local branch
  branch=$(git -C "$repo_path" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##') || true
  if [ -z "$branch" ]; then
    branch=$(git -C "$repo_path" branch --show-current 2>/dev/null) || true
  fi
  echo "$branch"
}

list_worktrees() { # repo -> newline list of window names, one per existing worktree path only
  local repo="$1"
  local wt_dir="$PROJECTS_DIR/${repo}.wt"
  local default_name
  default_name=$(default_branch_window_name "$repo")
  if [ -n "$default_name" ]; then
    echo "$default_name"
  fi
  if [ -d "$wt_dir" ]; then
    for w in "$wt_dir"/*; do
      [ -d "$w" ] || continue
      basename "$w"
    done
  fi
}

worktree_path() { # repo name, window name -> filesystem path
  local repo="$1" name="$2"
  local default_name
  default_name=$(default_branch_window_name "$repo")
  if [ -n "$default_name" ] && [ "$name" = "$default_name" ]; then
    echo "$PROJECTS_DIR/$repo"
  else
    echo "$PROJECTS_DIR/${repo}.wt/${name}"
  fi
}

session_name_for_repo() { # repo -> configured session name, or repo itself
  local repo="$1"
  [ -f "$SESSION_NAMES_CONF" ] || { echo "$repo"; return; }
  local mapped
  mapped=$(grep -m1 "^${repo}=" "$SESSION_NAMES_CONF" | cut -d= -f2-)
  [ -n "$mapped" ] && echo "$mapped" || echo "$repo"
}

jump_to_window() { # repo, worktree/window name -> creates if needed, switches
  local repo="$1" name="$2"
  local session; session=$(session_name_for_repo "$repo")
  if tmux has-session -t "$session" 2>/dev/null \
      && tmux list-windows -t "$session" -F '#{window_name}' | grep -qx "$name"; then
    tmux switch-client -t "${session}:${name}"
    return
  fi
  local path; path=$(worktree_path "$repo" "$name")
  if ! tmux has-session -t "$session" 2>/dev/null; then
    tmux new-session -d -s "$session" -n "$name" -c "$path" 'nvim'
  else
    tmux new-window -t "$session" -n "$name" -c "$path" 'nvim'
  fi
  tmux switch-client -t "${session}:${name}"
}

drill_repo() { # level 2: pick an exact window/worktree for one repo
  # returns 1 (picks nothing) on Esc, so the caller can go back to level 1
  local repo="$1"
  local session; session=$(session_name_for_repo "$repo")
  local open_windows
  open_windows=$(tmux list-windows -t "$session" -F '#{window_name}' 2>/dev/null || true)
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

build_level1() { # one line per repo (with or without a .wt dir), then any other live session not already covered by a repo
  local repo_dir repo session
  local -A claimed_sessions=()
  for repo_dir in "$PROJECTS_DIR"/*/; do
    repo_dir="${repo_dir%/}"
    [ -d "$repo_dir" ] || continue
    case "$repo_dir" in
      *.wt) continue ;; # worktree container, not a selectable repo on its own
    esac
    [ -d "$repo_dir/.git" ] || [ -f "$repo_dir/.git" ] || continue
    repo=$(basename "$repo_dir")
    session=$(session_name_for_repo "$repo")
    claimed_sessions["$session"]=1
    if tmux has-session -t "$session" 2>/dev/null; then
      echo "$repo"
    else
      echo "${repo} (new)"
    fi
  done
  local live
  while IFS= read -r live; do
    [ -z "$live" ] && continue
    [ -n "${claimed_sessions[$live]:-}" ] && continue
    echo "$live"
  done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
}

is_known_repo() { # repo name -> 0 if it has a matching directory under Projects/, 1 otherwise
  local repo="$1"
  local repo_path="$PROJECTS_DIR/$repo"
  { [ -d "$repo_path/.git" ] || [ -f "$repo_path/.git" ]; } && [ -d "$repo_path" ]
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
    if ! is_known_repo "$repo"; then
      continue # no worktree structure to drill into; Tab is a no-op here
    fi
    if drill_repo "$repo"; then
      exit 0
    else
      continue # Esc'd out of the drill-down; back to the session list, query preserved
    fi
  fi

  session=$(session_name_for_repo "$repo")
  if tmux has-session -t "$session" 2>/dev/null; then
    tmux switch-client -t "$session"
    exit 0
  else
    default_name=$(default_branch_window_name "$repo")
    jump_to_window "$repo" "${default_name:-main}"
    exit 0
  fi
done
