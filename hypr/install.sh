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

# session-wide env (systemd user manager, uwsm, etc.)
for f in "$DIR"/environment.d/*.conf; do
    [ -e "$f" ] || continue
    mkdir -p "$HOME/.config/environment.d"
    ln -sfn "$f" "$HOME/.config/environment.d/$(basename "$f")"
    echo "linked $HOME/.config/environment.d/$(basename "$f") -> $f"
done

# apply env vars to the running user session (best effort)
if command -v systemctl >/dev/null && systemctl --user show-environment >/dev/null 2>&1; then
    while IFS= read -r assignment; do
        systemctl --user set-environment "$assignment" 2>/dev/null || true
    done < <(grep -hE '^[A-Za-z_][A-Za-z0-9_]*=' "$DIR"/environment.d/*.conf 2>/dev/null)
    systemctl --user show-environment | grep -qF "$(grep -hE '^' "$DIR"/environment.d/*.conf | head -1 | cut -d= -f1)" \
        && echo "applied environment.d vars to running session" || true
fi

hyprctl reload >/dev/null 2>&1 && echo "hyprland reloaded" || echo "hyprland not running (skip reload)"
