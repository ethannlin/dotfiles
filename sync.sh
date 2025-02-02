#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Define paths
DOTFILES_REPO="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"

# Print status messages
print_status() {
    echo -e "${GREEN}=>${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}=>${NC} $1"
}

# function to sync config files
sync_configs() {
    # create directories if they don't exist
    mkdir -p "$DOTFILES_REPO/tmux"
    mkdir -p "$DOTFILES_REPO/ghostty"
    mkdir -p "$DOTFILES_REPO/starship"
    # add more directories as needed

    # sync tmux config
    if [ -f "$HOME/.tmux.conf" ]; then
        cp "$HOME/.tmux.conf" "$DOTFILES_REPO/tmux/.tmux.conf"
        print_status "Synced tmux config"
    fi

    # sync ghostty config
    if [ -f "$CONFIG_DIR/ghostty/config" ]; then
        cp "$CONFIG_DIR/ghostty/config" "$DOTFILES_REPO/ghostty/"
        print_status "Synced ghostty config"
    fi

    # Sync starship config
    if [ -f "$CONFIG_DIR/starship.toml" ]; then
        cp "$CONFIG_DIR/starship.toml" "$DOTFILES_REPO/starship/"
        print_status "Synced starship config"
    fi

    # add git commands
    cd "$DOTFILES_REPO" || exit
    
    # check if there are any changes
    if git diff --quiet && git diff --staged --quiet; then
        print_warning "No changes to commit"
        exit 0
    fi

    echo "Enter commit message (press enter for default message):"
    read -r commit_msg
    
    if [ -z "$commit_msg" ]; then
        commit_msg="Update dotfiles $(date +%Y-%m-%d)"
    fi

    # stage and commit changes
    git add .
    git commit -m "$commit_msg"
    
    echo "Do you want to push the changes to GitHub? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        git push
        print_status "Changes pushed to GitHub"
    else
        print_warning "Changes committed but not pushed"
    fi
}

# Main execution
if [ ! -d "$DOTFILES_REPO" ]; then
    print_warning "Dotfiles repository not found at $DOTFILES_REPO"
    exit 1
fi

sync_configs