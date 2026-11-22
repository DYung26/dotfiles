#!/usr/bin/env bash
# Level 1 lists repositories and standalone sessions. Enter switches to a
# session (creating a repo session on its primary checkout when needed); Tab
# opens that repo's registered worktrees. Esc returns to level 1 with query kept.
# Windows are identified by canonical checkout path. Grove aliases under
# <repo>.wt retain their names; other worktrees use branch names. Unregistered
# and prunable worktrees are excluded. session-names.conf overrides repo sessions.
set -euo pipefail

if [[ -n "${TMUX_SWITCHER_PROJECTS_DIR:-}" ]]; then
  PROJECTS_DIR=$TMUX_SWITCHER_PROJECTS_DIR
elif [[ -d /workspaces ]]; then
  PROJECTS_DIR=/workspaces
else
  PROJECTS_DIR=$HOME/Projects
fi

DOTFILES_DIR=${TMUX_SWITCHER_DOTFILES_DIR:-$PROJECTS_DIR/dotfiles}
SESSION_NAMES_CONF=$DOTFILES_DIR/tmux/.tmux/session-names.conf

declare -a WORKTREE_NAMES=()
declare -a WORKTREE_PATHS=()
declare -A WORKTREE_ALIAS_NAMES=()
declare -A SESSION_NAME_OVERRIDES=()
declare -A ACTIVE_SESSIONS=()
declare -A TMUX_WORKTREE_WINDOW_PATHS=()
declare -A TMUX_WORKTREE_WINDOW_BY_PATH=()
declare -a TMUX_WINDOW_IDS=()
declare -a TMUX_WINDOW_SESSION_IDS=()
declare -a TMUX_WINDOW_SESSION_NAMES=()
declare -a TMUX_WINDOW_NAMES=()
declare -a TMUX_WINDOW_CANONICAL_PATHS=()
TMUX_WINDOW_SNAPSHOT_LOADED=0
declare -a LEVEL1_KINDS=()
declare -a LEVEL1_VALUES=()
declare -a LEVEL1_LABELS=()

error() {
  printf 'tmux switcher: %s\n' "$*" >&2
  tmux display-message -d 5000 "tmux switcher: $*" 2>/dev/null || true
  return 1
}

load_session_name_overrides() {
  local line repo mapped

  SESSION_NAME_OVERRIDES=()
  [[ -f $SESSION_NAMES_CONF ]] || return 0

  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%$'\r'}
    [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
    [[ $line == *=* ]] || continue

    repo=${line%%=*}
    mapped=${line#*=}
    [[ -n $repo && -n $mapped ]] || continue
    [[ -n ${SESSION_NAME_OVERRIDES[$repo]:-} ]] || SESSION_NAME_OVERRIDES["$repo"]=$mapped
  done < "$SESSION_NAMES_CONF"
}

session_name_for_repo() {
  local repo=$1
  printf '%s\n' "${SESSION_NAME_OVERRIDES[$repo]:-$repo}"
}

default_branch_window_name() {
  local repo=$1
  local repo_path=$PROJECTS_DIR/$repo
  local branch=

  [[ -d $repo_path/.git || -f $repo_path/.git ]] || return 1

  branch=$(git -C "$repo_path" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
  branch=${branch#origin/}

  if [[ -z $branch ]]; then
    branch=$(git -C "$repo_path" branch --show-current 2>/dev/null || true)
  fi

  if [[ -z $branch ]]; then
    branch="detached-$(git -C "$repo_path" rev-parse --short HEAD 2>/dev/null || printf 'primary')"
  fi

  printf '%s\n' "$branch"
}

append_worktree_entry() {
  local repo=$1
  local repo_path=$2
  local path=$3
  local branch=$4
  local head=$5
  local canonical name

  [[ -n $path && -d $path ]] || return 0
  canonical=$(realpath -e -- "$path") || return 0

  if [[ $canonical == "$repo_path" ]]; then
    name=$(default_branch_window_name "$repo") || return 1
  elif [[ -n ${WORKTREE_ALIAS_NAMES[$canonical]:-} ]]; then
    name=${WORKTREE_ALIAS_NAMES[$canonical]}
  elif [[ -n $branch ]]; then
    name=$branch
  elif [[ -n $head ]]; then
    name="detached-${head:0:8}-${path##*/}"
  else
    name=${path##*/}
  fi

  WORKTREE_NAMES+=("$name")
  WORKTREE_PATHS+=("$canonical")
}

sort_worktree_entries() {
  local index entry
  local -a entries=() names=() paths=()

  mapfile -t entries < <(
    for index in "${!WORKTREE_NAMES[@]}"; do
      printf '%s\037%s\n' "${WORKTREE_NAMES[$index]}" "$index"
    done | sort -t $'\037' -k1,1
  )

  for entry in "${entries[@]}"; do
    index=${entry##*$'\037'}
    names+=("${WORKTREE_NAMES[$index]}")
    paths+=("${WORKTREE_PATHS[$index]}")
  done

  WORKTREE_NAMES=("${names[@]}")
  WORKTREE_PATHS=("${paths[@]}")
}

load_worktrees() {
  local repo=$1
  local repo_path=$PROJECTS_DIR/$repo
  local canonical_repo_path field record_path branch head prunable
  local worktree_dir alias alias_name alias_path

  WORKTREE_NAMES=()
  WORKTREE_PATHS=()
  WORKTREE_ALIAS_NAMES=()

  [[ -d $repo_path/.git || -f $repo_path/.git ]] || return 1
  canonical_repo_path=$(realpath -e -- "$repo_path") || return 1
  worktree_dir=$PROJECTS_DIR/${repo}.wt

  if [[ -d $worktree_dir ]]; then
    for alias in "$worktree_dir"/*; do
      [[ -d $alias ]] || continue
      alias_name=${alias##*/}
      case $alias_name in
        *.grove-bak|.stfolder) continue ;;
      esac
      alias_path=$(realpath -e -- "$alias" 2>/dev/null || true)
      [[ -n $alias_path ]] || continue
      [[ -n ${WORKTREE_ALIAS_NAMES[$alias_path]:-} ]] || WORKTREE_ALIAS_NAMES["$alias_path"]=$alias_name
    done
  fi

  record_path=
  branch=
  head=
  prunable=0

  while IFS= read -r -d '' field; do
    if [[ -z $field ]]; then
      if [[ -n $record_path && $prunable == 0 ]]; then
        append_worktree_entry "$repo" "$canonical_repo_path" "$record_path" "$branch" "$head"
      fi
      record_path=
      branch=
      head=
      prunable=0
      continue
    fi

    case $field in
      "worktree "*) record_path=${field#worktree } ;;
      "branch "*) branch=${field#branch refs/heads/} ;;
      "HEAD "*) head=${field#HEAD } ;;
      prunable*) prunable=1 ;;
    esac
  done < <(git -C "$repo_path" worktree list --porcelain -z)

  if [[ -n $record_path && $prunable == 0 ]]; then
    append_worktree_entry "$repo" "$canonical_repo_path" "$record_path" "$branch" "$head"
  fi
  sort_worktree_entries
}

# Psmux stores @options at session scope, so key each value by both IDs.
worktree_window_option_name() {
  local session_id=$1
  local window_id=$2

  [[ -n $session_id && -n $window_id ]] || return 1
  session_id=${session_id//[^[:alnum:]_]/_}
  window_id=${window_id//[^[:alnum:]_]/_}
  printf '@tmux_switcher_worktree_path_%s_%s' "$session_id" "$window_id"
}

load_tmux_window_snapshot() {
  local option value suffix window_id session_id session_name name current_path canonical_current_path stored_path key

  TMUX_WORKTREE_WINDOW_PATHS=()
  TMUX_WORKTREE_WINDOW_BY_PATH=()
  TMUX_WINDOW_IDS=()
  TMUX_WINDOW_SESSION_IDS=()
  TMUX_WINDOW_SESSION_NAMES=()
  TMUX_WINDOW_NAMES=()
  TMUX_WINDOW_CANONICAL_PATHS=()

  # Fetch recorded paths and windows once instead of spawning tmux for every
  # worktree/window pair.
  while IFS='|' read -r option value; do
    [[ $option == @tmux_switcher_worktree_path_* ]] || continue
    suffix=${option#@tmux_switcher_worktree_path_}
    TMUX_WORKTREE_WINDOW_PATHS["$suffix"]=$value
  done < <(tmux show-options -g -F '#{option_name}|#{option_value}' 2>/dev/null || true)

  while IFS='|' read -r window_id session_id session_name name current_path; do
    [[ -n $window_id ]] || continue

    option=$(worktree_window_option_name "$session_id" "$window_id") || continue
    suffix=${option#@tmux_switcher_worktree_path_}
    stored_path=${TMUX_WORKTREE_WINDOW_PATHS[$suffix]:-}
    if [[ -n $stored_path && -d $stored_path ]]; then
      canonical_current_path=
    else
      canonical_current_path=$(realpath -e -- "$current_path" 2>/dev/null || true)
    fi

    TMUX_WINDOW_IDS+=("$window_id")
    TMUX_WINDOW_SESSION_IDS+=("$session_id")
    TMUX_WINDOW_SESSION_NAMES+=("$session_name")
    TMUX_WINDOW_NAMES+=("$name")
    TMUX_WINDOW_CANONICAL_PATHS+=("$canonical_current_path")

    if [[ -n $stored_path && -d $stored_path ]]; then
      key="${session_name}"$'\037'"${stored_path}"
      [[ -n ${TMUX_WORKTREE_WINDOW_BY_PATH[$key]:-} ]] || TMUX_WORKTREE_WINDOW_BY_PATH["$key"]=$window_id
    fi
  done < <(tmux list-windows -a -F '#{window_id}|#{session_id}|#{session_name}|#{window_name}|#{pane_current_path}' 2>/dev/null || true)

  TMUX_WINDOW_SNAPSHOT_LOADED=1
}

find_window_for_worktree() {
  local session=$1
  local name=$2
  local path=$3
  local key index window_id session_id option suffix stored_path current_name current_path

  ((TMUX_WINDOW_SNAPSHOT_LOADED)) || load_tmux_window_snapshot

  key="${session}"$'\037'"${path}"
  if [[ -n ${TMUX_WORKTREE_WINDOW_BY_PATH[$key]:-} ]]; then
    printf '%s' "${TMUX_WORKTREE_WINDOW_BY_PATH[$key]}"
    return 0
  fi

  # Legacy windows without a recorded path need the slower name/path fallback.
  for index in "${!TMUX_WINDOW_IDS[@]}"; do
    [[ ${TMUX_WINDOW_SESSION_NAMES[$index]} == "$session" ]] || continue

    window_id=${TMUX_WINDOW_IDS[$index]}
    session_id=${TMUX_WINDOW_SESSION_IDS[$index]}
    option=$(worktree_window_option_name "$session_id" "$window_id") || continue
    suffix=${option#@tmux_switcher_worktree_path_}
    stored_path=${TMUX_WORKTREE_WINDOW_PATHS[$suffix]:-}

    if [[ $stored_path == "$path" ]]; then
      TMUX_WORKTREE_WINDOW_BY_PATH["$key"]=$window_id
      printf '%s' "$window_id"
      return 0
    fi

    if [[ -z $stored_path || ! -d $stored_path ]]; then
      current_name=${TMUX_WINDOW_NAMES[$index]}
      current_path=${TMUX_WINDOW_CANONICAL_PATHS[$index]}

      if [[ $current_name == "$name" && ( $current_path == "$path" || $current_path == "$path"/* ) ]]; then
        tmux set-option -g "$option" "$path" 2>/dev/null || true
        TMUX_WORKTREE_WINDOW_PATHS["$suffix"]=$path
        TMUX_WORKTREE_WINDOW_BY_PATH["$key"]=$window_id
        printf '%s' "$window_id"
        return 0
      fi
    fi
  done

  return 1
}

switch_to_window() {
  local session=$1
  local window_id=$2

  tmux select-window -t "$session:$window_id" || return 1
  tmux switch-client -t "$session"
}

switch_to_worktree() {
  local repo=$1
  local name=$2
  local path=$3
  local session window_id session_id option
  local session_exists=0

  [[ -d $path ]] || { error "Worktree no longer exists: $path"; return 1; }
  path=$(realpath -e -- "$path") || { error "Could not resolve worktree path: $path"; return 1; }
  session=$(session_name_for_repo "$repo")

  if tmux has-session -t "=$session" 2>/dev/null; then
    session_exists=1
    if window_id=$(find_window_for_worktree "$session" "$name" "$path"); then
      switch_to_window "$session" "$window_id"
      return
    fi
  fi

  command -v nvim >/dev/null 2>&1 || { error "nvim is required to open a new worktree window"; return 1; }

  if ((session_exists)); then
    window_id=$(tmux new-window -d -P -F '#{window_id}' -t "=$session" -n "$name" -c "$path" nvim) || {
      error "Could not create a window for $repo/$name"
      return 1
    }
  else
    window_id=$(tmux new-session -d -P -F '#{window_id}' -s "$session" -n "$name" -c "$path" nvim) || {
      if tmux has-session -t "=$session" 2>/dev/null; then
        window_id=$(tmux new-window -d -P -F '#{window_id}' -t "=$session" -n "$name" -c "$path" nvim) || {
          error "Could not create a window for $repo/$name"
          return 1
        }
      else
        error "Could not create tmux session $session"
        return 1
      fi
    }
  fi

  [[ -n $window_id ]] || { error "tmux did not return a window ID for $repo/$name"; return 1; }
  session_id=$(tmux display-message -p -t "$window_id" '#{session_id}') || {
    error "Could not identify the session for $repo/$name"
    return 1
  }
  option=$(worktree_window_option_name "$session_id" "$window_id") || {
    error "Could not identify the window for $repo/$name"
    return 1
  }
  tmux set-option -g "$option" "$path" || {
    error "Could not record the worktree path for $repo/$name"
    return 1
  }
  switch_to_window "$session" "$window_id"
}

append_level1_entry() {
  LEVEL1_KINDS+=("$1")
  LEVEL1_VALUES+=("$2")
  LEVEL1_LABELS+=("$3")
}

sort_level1_entries() {
  local index entry
  local -a entries=() kinds=() values=() labels=()

  mapfile -t entries < <(
    for index in "${!LEVEL1_LABELS[@]}"; do
      printf '%s\037%s\n' "${LEVEL1_LABELS[$index]}" "$index"
    done | sort -t $'\037' -k1,1
  )

  for entry in "${entries[@]}"; do
    index=${entry##*$'\037'}
    kinds+=("${LEVEL1_KINDS[$index]}")
    values+=("${LEVEL1_VALUES[$index]}")
    labels+=("${LEVEL1_LABELS[$index]}")
  done

  LEVEL1_KINDS=("${kinds[@]}")
  LEVEL1_VALUES=("${values[@]}")
  LEVEL1_LABELS=("${labels[@]}")
}

load_active_sessions() {
  local live

  ACTIVE_SESSIONS=()
  while IFS= read -r live; do
    [[ -n $live ]] && ACTIVE_SESSIONS["$live"]=1
  done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
}

build_level1() {
  local repo_dir repo session live label
  local -A claimed_sessions=()

  load_active_sessions
  LEVEL1_KINDS=()
  LEVEL1_VALUES=()
  LEVEL1_LABELS=()

  for repo_dir in "$PROJECTS_DIR"/*/; do
    [[ -d $repo_dir ]] || continue
    repo_dir=${repo_dir%/}
    [[ -d $repo_dir/.git || -f $repo_dir/.git ]] || continue

    repo=${repo_dir##*/}
    session=$(session_name_for_repo "$repo")
    claimed_sessions["$session"]=1

    if [[ -n ${ACTIVE_SESSIONS[$session]:-} ]]; then
      label=$repo
    else
      label="$repo (new)"
    fi

    append_level1_entry repo "$repo" "$label"
  done

  for live in "${!ACTIVE_SESSIONS[@]}"; do
    [[ -n ${claimed_sessions[$live]:-} ]] && continue
    append_level1_entry session "$live" "$live"
  done

  sort_level1_entries
}

select_level1_entry() {
  local query=$1
  local result
  local -a response=()
  local index

  result=$(
    for index in "${!LEVEL1_LABELS[@]}"; do
      printf '%s:%s\n' "$index" "${LEVEL1_LABELS[$index]}"
    done | fzf --reverse --cycle --delimiter=: --with-nth=2.. \
      --expect=tab --query "$query" --print-query \
      --header 'Enter: switch  |  Tab: choose worktree'
  ) || true

  mapfile -t response <<< "$result"
  SELECTED_QUERY=${response[0]-$query}
  SELECTED_KEY=${response[1]-}
  SELECTED_INDEX=${response[2]-}
  SELECTED_INDEX=${SELECTED_INDEX%%:*}
}

select_worktree() {
  local repo=$1
  local session index name path label window_id result
  local -a response=()

  session=$(session_name_for_repo "$repo")
  load_worktrees "$repo" || { error "Could not inspect worktrees for $repo"; return 1; }
  load_tmux_window_snapshot

  if ((${#WORKTREE_NAMES[@]} == 0)); then
    error "No checkout or worktrees found for $repo"
    return 1
  fi

  result=$(
    for index in "${!WORKTREE_NAMES[@]}"; do
      name=${WORKTREE_NAMES[$index]}
      path=${WORKTREE_PATHS[$index]}
      if window_id=$(find_window_for_worktree "$session" "$name" "$path"); then
        label="$name  [open]"
      else
        label="$name  [new]"
      fi
      printf '%s:%s\n' "$index" "$label"
    done | fzf --reverse --cycle --delimiter=: --with-nth=2.. \
      --print-query --header "$repo: choose a checkout/worktree  (Esc: back)"
  ) || true

  mapfile -t response <<< "$result"
  index=${response[1]-}
  index=${index%%:*}
  [[ $index =~ ^[0-9]+$ ]] || return 1
  ((index < ${#WORKTREE_NAMES[@]})) || return 1

  switch_to_worktree "$repo" "${WORKTREE_NAMES[$index]}" "${WORKTREE_PATHS[$index]}"
}

main() {
  local query=
  local index repo session primary_name primary_path

  [[ -d $PROJECTS_DIR ]] || { error "Projects directory not found: $PROJECTS_DIR"; return 1; }
  load_session_name_overrides
  local dependency
  for dependency in fzf git realpath sort; do
    command -v "$dependency" >/dev/null 2>&1 || { error "$dependency is required but was not found in PATH"; return 1; }
  done

  while true; do
    build_level1
    select_level1_entry "$query"
    query=$SELECTED_QUERY

    [[ $SELECTED_INDEX =~ ^[0-9]+$ ]] || return 0
    ((SELECTED_INDEX < ${#LEVEL1_KINDS[@]})) || return 0

    index=$SELECTED_INDEX
    repo=${LEVEL1_VALUES[$index]}
    session=$(session_name_for_repo "$repo")

    if [[ $SELECTED_KEY == tab ]]; then
      [[ ${LEVEL1_KINDS[$index]} == repo ]] || continue
      select_worktree "$repo" || continue
      return
    fi

    if [[ ${LEVEL1_KINDS[$index]} == session ]]; then
      tmux switch-client -t "=$session"
      return
    fi

    if tmux has-session -t "=$session" 2>/dev/null; then
      tmux switch-client -t "=$session"
      return
    fi

    primary_name=$(default_branch_window_name "$repo") || { error "Could not determine the primary checkout for $repo"; return 1; }
    primary_path=$(realpath -e -- "$PROJECTS_DIR/$repo") || { error "Primary checkout no longer exists for $repo"; return 1; }
    switch_to_worktree "$repo" "$primary_name" "$primary_path"
    return
  done
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
