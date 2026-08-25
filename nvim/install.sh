#!/usr/bin/env bash
# Links the Neovim config into ~/.config/nvim.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup-$TS"

if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
    mkdir -p "$BACKUP"
    mv "$HOME/.config/nvim" "$BACKUP/"
    echo "backed up old config to $BACKUP/nvim"
fi

ln -sfn "$DIR" "$HOME/.config/nvim"
echo "linked $HOME/.config/nvim -> $DIR"
