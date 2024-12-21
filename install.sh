#!/bin/bash

# # WSL
# In order to use the git-credential-manager (recommended) you must install Git for windows to its default location.

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

function pkg() {
    echo "Installing: $@"

    sudo apt install -qy "$@"
}

function install_font() {
    mkdir -p ~/.local/share/fonts
    pushd ~/.local/share/fonts

    local font_zip=$(basename $1)

    if ! [ -f "$font_zip" ]; then
        curl -LO $1
        unzip $font_zip

        # rebuild font cache
        fc-cache -f -v
    fi

    popd
}

function ensure_venv() {
    if ! [ -d "$HOME/.venvs/$1" ]; then
        pushd ~/.venvs

        python3 -m venv "$1"

        popd
    fi

    source "$HOME/.venvs/$1/bin/activate"

    python3 -m pip install --upgrade ${@:2}

    deactivate
}

sudo apt update

if [ -v WSL_DISTRO_NAME ]; then
    # Needed to run AppImages
    pkg libfuse2

    # Setup git to use the Git for windows credential manager.
    # https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-git#git-credential-manager-setup
    git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
fi

# Setup user bin folder. Note that on Ubuntu this will be on the path.
# Note that if it did not exist, a re-login will be needed before it is added to the path
mkdir ~/bin

pkg curl

pkg fish

# Node
if ! [ -f ~/.nvm/nvm.sh ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
. ~/.nvm/nvm.sh
nvm install 22

# Neovim
nvim_path=~/bin/nvim
if ! [ -f "$nvim_path" ]; then
    curl --output-dir $SCRIPT_DIR -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    mv -f $SCRIPT_DIR/nvim.appimage $nvim_path
    chmod u+x $nvim_path
fi

# Setup python venvs
mkdir ~/.venvs
pkg python3-pip python3-venv

ensure_venv py3nvim \
    pynvim

# LazyVim deps
pkg clang fd-find fzf chafa ripgrep lua5.1 luarocks cargo

pkg perl
curl -L https://cpanmin.us | perl - --sudo App::cpanminus
sudo cpanm -n Neovim::Ext

pkg ruby ruby-dev
sudo gem install neovim

npm install -g neovim

# Fonts
install_font https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/ProggyClean.zip
install_font https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Gohu.zip

# Terminals
# Note that you do not typlically want to run the terminal inside WSL.
if ! [ -v WSL_DISTRO_NAME ]; then
    pkg alacritty
fi

# Bun
if ! command -v bun; then
    curl -fsSL https://bun.sh/install | bash
fi

# LazyGit
if ! command -v lazygit; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit -D -t ~/bin/
fi

# Stow
pkg stow
pushd ~/.dotfiles
stow nvim
stow alacritty
popd
