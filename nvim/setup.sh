#!/bin/bash

# Define the Neovim config directory
NVIM_CONFIG_DIR="$HOME/.config/nvim"

# Get the current directory
CURRENT_DIR=$(pwd)

# Check if the symlink or directory already exists
if [ -e "$NVIM_CONFIG_DIR" ] || [ -L "$NVIM_CONFIG_DIR" ]; then
    echo "Removing existing Neovim configuration..."
    rm -rf "$NVIM_CONFIG_DIR"
fi

# Create the symbolic link
ln -s "$CURRENT_DIR" "$NVIM_CONFIG_DIR"

echo "Symlink created: $CURRENT_DIR -> $NVIM_CONFIG_DIR"
