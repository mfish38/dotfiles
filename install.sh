#!/bin/bash

SCRIPT_DIR=$(dirname "$( readlink -f "$0"; )")

function pkg() {
    echo "Installing: $@"

    sudo apt install -qy "$@"
}

pkg curl

# Setup user bin folder. Note that on Ubuntu this will be on the path.
# Note that if it did not exist, a re-login will be needed before it is added to the path
mkdir ~/bin

# Neovim
nvim_path=~/bin/nvim
if ! [ -f "$nvim_path" ]; then
    curl --output-dir $SCRIPT_DIR -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    mv -f $SCRIPT_DIR/nvim.appimage $nvim_path
    chmod u+x $nvim_path
fi

