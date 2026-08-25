#!/usr/bin/env bash
# Symlinks the synced configs into ~/.config.
# Run on any machine after Syncthing has synced this folder.
# Existing dirs/files are moved aside to ~/.config-backup-<timestamp>/.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup-$TS"

link_dir() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mkdir -p "$BACKUP"
        mv "$dst" "$BACKUP/"
    fi
    ln -sfn "$src" "$dst"
    echo "linked $dst -> $src"
}

link_dir "$DIR/hypr" "$HOME/.config/hypr"

mkdir -p "$HOME/.config/noctalia"
if [ -e "$HOME/.config/noctalia/config.toml" ] && [ ! -L "$HOME/.config/noctalia/config.toml" ]; then
    mkdir -p "$BACKUP"
    mv "$HOME/.config/noctalia/config.toml" "$BACKUP/"
fi
ln -sfn "$DIR/noctalia/config.toml" "$HOME/.config/noctalia/config.toml"
echo "linked $HOME/.config/noctalia/config.toml -> $DIR/noctalia/config.toml"

echo "Done. Backups (if any): $BACKUP"
echo "Reload with: hyprctl reload && noctalia msg config-reload"
