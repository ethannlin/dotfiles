#!/bin/bash
set -euo pipefail

CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$HOME/Desktop/dotfiles"

# DRY_RUN=1 prints every mutating command instead of running it.
#   DRY_RUN=1 ./install.sh
DRY_RUN="${DRY_RUN:-0}"
run() {
    if [ "$DRY_RUN" = "1" ]; then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}

if [ "$DRY_RUN" = "1" ]; then
    echo ">>> DRY RUN — showing what would happen, installing nothing <<<"
    echo ""
fi

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
run brew tap FelixKratz/formulae   # provides 'borders' (JankyBorders)
run brew install starship borders
run brew install --cask nikitabobko/tap/aerospace ghostty

# fonts used by ghostty / the prompt
run brew install --cask font-sf-mono font-sf-pro font-meslo-lg-nerd-font

# --- oh-my-zsh + external plugins -----------------------------------------
# .zshrc assumes oh-my-zsh plus two external plugins (zsh-autosuggestions,
# zsh-syntax-highlighting). Install unattended so it doesn't switch shells or
# clobber our symlinked .zshrc (the symlink step below overrides omz's default).
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    if [ "$DRY_RUN" = "1" ]; then
        echo '[dry-run] sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    else
        RUNZSH=no KEEP_ZSHRC=yes \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    run git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    run git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# --- config directories ---------------------------------------------------
echo "Creating config directories..."
run mkdir -p "$CONFIG_DIR/ghostty"
run mkdir -p "$CONFIG_DIR/aerospace"

# --- symlinks (source-in-repo : destination) ------------------------------
# Everything is symlinked so edits stay in-repo and sync via git.
links=(
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
        run mv "$dst" "$dst.backup"
        echo "Backed up existing $dst -> $dst.backup"
    fi

    run ln -sf "$DOTFILES_DIR/$src" "$dst"
    echo "Linked: $src -> $dst"
done

echo ""
echo "Dotfiles installation complete."
echo "Note: borders is launched by AeroSpace (after-startup-command in aerospace.toml)."
echo "Restart your terminal, then start AeroSpace to apply everything."
