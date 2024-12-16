#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

sudo apt update

function pkg() {
    echo "Installing: $@"

    sudo apt install -qy "$@"
}

function install_font() {
    mkdir -p ~/.local/share/fonts
    pushd ~/.local/share/fonts

    local font_zip=$(basename $1)

    if ! [ -f $font_zip ]; then
        curl -LO $1
        unzip $font_zip

        # rebuild font cache
        fc-cache -f -v
    fi

    popd
}

# Setup user bin folder. Note that on Ubuntu this will be on the path.
# Note that if it did not exist, a re-login will be needed before it is added to the path
mkdir ~/bin

pkg curl

# Neovim
nvim_path=~/bin/nvim
if ! [ -f "$nvim_path" ]; then
    curl --output-dir $SCRIPT_DIR -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    mv -f $SCRIPT_DIR/nvim.appimage $nvim_path
    chmod u+x $nvim_path
fi

# LazyVim deps
pkg clang ripgrep fd-find fzf

install_font https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/ProggyClean.zip
install_font https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Gohu.zip

# Cargo
pkg cargo
# TODO: add to .profile automatically:
# PATH="$HOME/.cargo/bin:$PATH"

# Alacrity
pkg cmake g++ pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
cargo install alacritty

# Stow
pkg stow
pushd ~/.dotfiles
stow nvim
stow alacritty
popd
