#!/usr/bin/env bash
# Meta-installer: choose which configs to link.
#
# Usage:
#   ./install.sh              # interactive menu
#   ./install.sh hypr noctalia  # run only these
#   ./install.sh all          # run everything
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# discover folders with an install.sh (sorted)
available=()
for d in "$DIR"/*/; do
    name="$(basename "$d")"
    [ -x "$d/install.sh" ] && available+=("$name")
done

if [ ${#available[@]} -eq 0 ]; then
    echo "no installable configs found in $DIR"
    exit 1
fi

# pick targets: from args, or interactively
targets=()
if [ $# -gt 0 ]; then
    for arg in "$@"; do
        if [ "$arg" = "all" ]; then
            targets=("${available[@]}")
            break
        fi
        found=0
        for a in "${available[@]}"; do
            [ "$arg" = "$a" ] && { targets+=("$arg"); found=1; break; }
        done
        [ $found -eq 0 ] && { echo "unknown config: $arg (available: ${available[*]})"; exit 1; }
    done
else
    echo "Available configs:"
    i=1
    for a in "${available[@]}"; do
        linked="no"
        [ -L "$HOME/.config/$a" ] || [ -L "$HOME/.config/$a/config.toml" ] && linked="yes"
        printf '  %d) %-10s (linked: %s)\n' "$i" "$a" "$linked"
        i=$((i + 1))
    done
    echo
    read -rp "Install which ones? (numbers separated by space, 'a' = all, 'q' = quit): " choice
    [ -z "$choice" ] && { echo "nothing selected"; exit 0; }
    if [ "$choice" = "q" ] || [ "$choice" = "quit" ]; then
        echo "nothing selected"; exit 0
    fi
    if [ "$choice" = "a" ] || [ "$choice" = "all" ]; then
        targets=("${available[@]}")
    else
        for num in $choice; do
            if [[ ! "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt ${#available[@]} ]; then
                echo "invalid selection: $num"; exit 1
            fi
            targets+=("${available[$((num - 1))]}")
        done
    fi
fi

# run the chosen sub-installers
echo
for t in "${targets[@]}"; do
    echo -e "\n\033[1;32m==> $t\033[0m"
    bash "$DIR/$t/install.sh"
done

echo -e "\nAll done: ${targets[*]}"
