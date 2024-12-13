#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

sudo apt update

function pkg() {
  echo "Installing: $@"

  sudo apt install -qy "$@"
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

# TODO: detect already installed
# mkdir -p ~/.local/share/fonts
# cd ~/.local/share/fonts
# FONT_URL=https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Meslo.zip
# curl -fLo "font.zip" $FONT_URL
# unzip font.zip
# fc-cache -f -v # rebuild font cache
# cd ~

# Cargo
pkg cargo
# TODO: add to .profile automatically:
# PATH="$HOME/.cargo/bin:$PATH"

# Alacrity
pkg cmake g++ pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
cargo install alacritty

# Stow
pkg stow
cd ~/.dotfiles
stow nvim
cd ~
