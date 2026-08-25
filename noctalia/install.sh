#!/usr/bin/env bash
# Links the Noctalia config into ~/.config/noctalia and reloads the shell.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup-$TS"

mkdir -p "$HOME/.config/noctalia"

if [ -e "$HOME/.config/noctalia/config.toml" ] && [ ! -L "$HOME/.config/noctalia/config.toml" ]; then
    mkdir -p "$BACKUP"
    mv "$HOME/.config/noctalia/config.toml" "$BACKUP/"
    echo "backed up old config to $BACKUP/config.toml"
fi

ln -sfn "$DIR/config.toml" "$HOME/.config/noctalia/config.toml"
echo "linked $HOME/.config/noctalia/config.toml -> $DIR/config.toml"

for d in palettes templates; do
    ln -sfn "$DIR/$d" "$HOME/.config/noctalia/$d"
    echo "linked $HOME/.config/noctalia/$d -> $DIR/$d"
done

noctalia msg config-reload >/dev/null 2>&1 && echo "noctalia reloaded" || echo "noctalia not running (skip reload)"
