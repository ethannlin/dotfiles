#!/bin/bash

# Create necessary directories
mkdir -p ~/.config/ghostty

# Create symbolic links
ln -sf ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/ghostty/config ~/.config/ghostty/config
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

echo "Dotfiles installation complete!"
