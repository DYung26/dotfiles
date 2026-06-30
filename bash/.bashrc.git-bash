# stty intr ^T
alias gh-26='GH_CONFIG_DIR=~/.config/gh-dyung26 gh'
alias gh-06='GH_CONFIG_DIR=~/.config/gh-dyung06 gh'
alias gh-df='GH_CONFIG_DIR=~/.config/gh-dyungfirm gh'
alias gh-odo='GH_CONFIG_DIR=~/.config/gh-oyedanolu gh'

rmconflicts() {
    local count

    count=$(find . -type f -name "*.sync-conflict-*" | wc -l)

    if [ "$count" -eq 0 ]; then
        echo "No sync-conflict files found."
        return 0
    fi

    echo "Found $count sync-conflict file(s):"
    find . -type f -name "*.sync-conflict-*"
    echo

    read -rp "Delete them? [y/N] " confirm

    [[ "$confirm" =~ ^([yY]|yes|YES|Yes)$ ]] || {
        echo "Aborted."
        return 1
    }

    find . -type f -name "*.sync-conflict-*" -exec rm -fv {} \;
}

restoreconflicts() {
    local all=false opt count original conflict confirm

    while getopts "a" opt; do
        case "$opt" in
            a) all=true ;;
            *) echo "Usage: restoreconflicts [-a]"; return 1 ;;
        esac
    done

    local conflicts=()
    mapfile -t conflicts < <(find . -type f -name "*.sync-conflict-*")

    count=${#conflicts[@]}

    if [ "$count" -eq 0 ]; then
        echo "No sync-conflict files found."
        return 0
    fi

    echo "Found $count sync-conflict file(s):"
    printf '%s\n' "${conflicts[@]}"
    echo

    if [ "$all" = false ]; then
        read -rp "Review and restore them? [y/N] " confirm
        [[ "$confirm" =~ ^([yY]|yes|YES|Yes)$ ]] || {
            echo "Aborted."
            return 1
        }
    fi

    local backup_dir
    backup_dir=$(mktemp -d "${TMPDIR:-/tmp}/restoreconflicts-backup-XXXXXX")
    local restored_originals=() restored_conflicts=() restored_had_original=()
    local restored=0

    for conflict in "${conflicts[@]}"; do
        original=$(echo "$conflict" | sed -E 's/\.sync-conflict-[0-9]{8}-[0-9]{6}-[A-Z0-9]{7}//')

        if [ "$all" = false ]; then
            if [ -f "$original" ]; then
                echo "--- $original"
                echo "+++ $conflict"
                git --no-pager diff --no-index --color --ignore-cr-at-eol -- "$original" "$conflict"
                echo
                read -rp "Restore $conflict into $original? [y/N] " confirm
            else
                echo "No matching original found for $conflict (expected: $original)"
                read -rp "Restore it as $original anyway? [y/N] " confirm
            fi

            [[ "$confirm" =~ ^([yY]|yes|YES|Yes)$ ]] || {
                echo "Skipped $conflict."
                continue
            }
        fi

        local backup_subdir="$backup_dir/$restored"
        mkdir -p "$backup_subdir"
        cp -f "$conflict" "$backup_subdir/conflict"
        if [ -f "$original" ]; then
            cp -f "$original" "$backup_subdir/original"
            restored_had_original+=(true)
        else
            restored_had_original+=(false)
        fi
        restored_originals+=("$original")
        restored_conflicts+=("$conflict")

        cp -fv "$conflict" "$original"
        rm -fv "$conflict"
        restored=$((restored + 1))
    done

    echo "Restored $restored file(s)."

    if [ "$restored" -eq 0 ]; then
        rm -rf "$backup_dir"
        return 0
    fi

    echo "Backups saved in $backup_dir"
    read -rp "Keep these changes, or revert them? [K/r] " confirm
    if [[ "$confirm" =~ ^([rR]|revert|REVERT|Revert)$ ]]; then
        local i
        for ((i = 0; i < restored; i++)); do
            original="${restored_originals[$i]}"
            conflict="${restored_conflicts[$i]}"
            if [ "${restored_had_original[$i]}" = true ]; then
                cp -fv "$backup_dir/$i/original" "$original"
            else
                rm -fv "$original"
            fi
            cp -fv "$backup_dir/$i/conflict" "$conflict"
        done
        echo "Reverted $restored file(s)."
    else
        echo "Changes kept."
    fi

    rm -rf "$backup_dir"
}
