#!/bin/bash
set -euo pipefail

CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$HOME/Desktop/dotfiles"

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Error: Dotfiles directory not found at $DOTFILES_DIR"
    exit 1
fi

# --- dependencies ---------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
    echo "Error: Homebrew not found. Install it from https://brew.sh first."
    exit 1
fi

echo "Installing dependencies..."
brew tap FelixKratz/formulae   # provides 'borders' (JankyBorders)
brew install starship tmux borders
brew install --cask aerospace ghostty

# fonts used by ghostty / the prompt
brew install --cask font-sf-mono font-sf-pro font-meslo-lg-nerd-font

# --- oh-my-zsh + external plugins -----------------------------------------
# .zshrc assumes oh-my-zsh plus two external plugins (zsh-autosuggestions,
# zsh-syntax-highlighting). Install unattended so it doesn't switch shells or
# clobber our symlinked .zshrc (the symlink step below overrides omz's default).
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    RUNZSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# --- tmux plugin manager --------------------------------------------------
# .tmux.conf loads TPM from ~/.tmux/plugins/tpm and lists plugins it manages.
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing tmux plugin manager (tpm)..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# --- config directories ---------------------------------------------------
echo "Creating config directories..."
mkdir -p "$CONFIG_DIR/ghostty"
mkdir -p "$CONFIG_DIR/aerospace"

# --- symlinks (source-in-repo : destination) ------------------------------
# Everything is symlinked so edits stay in-repo and sync via git.
links=(
    "tmux/.tmux.conf:$HOME/.tmux.conf"
    "zsh/.zshrc:$HOME/.zshrc"
    "ghostty/config:$CONFIG_DIR/ghostty/config"
    "starship/starship.toml:$CONFIG_DIR/starship.toml"
    "aerospace/aerospace.toml:$CONFIG_DIR/aerospace/aerospace.toml"
)

echo "Creating symbolic links..."
for link in "${links[@]}"; do
    src="${link%%:*}"
    dst="${link#*:}"

    if [ ! -e "$DOTFILES_DIR/$src" ]; then
        echo "Warning: source not found, skipping: $DOTFILES_DIR/$src"
        continue
    fi

    # back up an existing real file/dir (not an existing symlink) before relinking
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mv "$dst" "$dst.backup"
        echo "Backed up existing $dst -> $dst.backup"
    fi

    ln -sf "$DOTFILES_DIR/$src" "$dst"
    echo "Linked: $src -> $dst"
done

# install tmux plugins non-interactively now that .tmux.conf is linked
if [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
fi

echo ""
echo "Dotfiles installation complete."
echo "Note: borders is launched by AeroSpace (after-startup-command in aerospace.toml)."
echo "Restart your terminal, then start AeroSpace to apply everything."
