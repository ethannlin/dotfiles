#!/bin/bash

CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$HOME/dotfiles"

# create all necessary directories
echo "Creating config directories..."
mkdir -p "$CONFIG_DIR/ghostty"

# check if dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Error: Dotfiles directory not found at $DOTFILES_DIR"
    exit 1
fi

# create symbolic links and check for success
echo "Creating symbolic links..."

# array of files to link (source:destination)
links=(
    "tmux/.tmux.conf:$HOME/.tmux.conf"
    "ghostty/config:$CONFIG_DIR/ghostty/config"
    "starship/starship.toml:$CONFIG_DIR/starship.toml"
)

# create each symlink
for link in "${links[@]}"; do
    src="${link%%:*}"
    dst="${link#*:}"
    
    if [ ! -f "$DOTFILES_DIR/$src" ]; then
        echo "Warning: Source file not found: $DOTFILES_DIR/$src"
        continue
    fi

    ln -sf "$DOTFILES_DIR/$src" "$dst" && echo "Linked: $src → $dst"
done

echo "Dotfiles installation complete!"