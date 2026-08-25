#!/usr/bin/env bash
# Links the Hyprland config into ~/.config and reloads.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup-$TS"

if [ -e "$HOME/.config/hypr" ] && [ ! -L "$HOME/.config/hypr" ]; then
    mkdir -p "$BACKUP"
    mv "$HOME/.config/hypr" "$BACKUP/"
    echo "backed up old config to $BACKUP/hypr"
fi

ln -sfn "$DIR" "$HOME/.config/hypr"
echo "linked $HOME/.config/hypr -> $DIR"

hyprctl reload >/dev/null 2>&1 && echo "hyprland reloaded" || echo "hyprland not running (skip reload)"
