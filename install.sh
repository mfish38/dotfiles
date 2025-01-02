#!/bin/bash

pushd ~/.dotfiles || exit

# # WSL
# In order to use the git-credential-manager (recommended) you must install Git for windows to its default location.

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

#######################################
# Installs a package using apt.
# Arguments:
#   List of Packages to install.
#######################################
function pkg() {
    echo "Installing: $*"

    sudo apt install -qy "$@"
}

#######################################
# Ensures a luarock is installed.
# Arguments:
#   The luarock to install.
#######################################
function ensure_luarock() {
    local current
    current=$(luarocks show --mversion "$1" 2>/dev/null)

    # shellcheck disable=SC2181
    if [ $? != 0 ]; then
        sudo luarocks install --lua-version 5.1 "$1"

        return 0
    fi

    local latest
    latest=$(luarocks search --porcelain "$1" | head -n 1 | cut -f 2)

    if [ "$current" != "$latest" ]; then
        sudo luarocks install --lua-version 5.1 "$1"

        return 0
    fi
}

#######################################
# Installs a font.
# Arguments:
#   Url to download the font from.
#######################################
function install_font() {
    mkdir -p ~/.local/share/fonts
    pushd ~/.local/share/fonts || return 1

    local font_zip
    font_zip=$(basename "$1")

    if ! [ -f "$font_zip" ]; then
        curl -LO "$1"
        unzip "$font_zip"

        # rebuild font cache
        fc-cache -f -v
    fi

    popd || return 1
}

#######################################
# Creates a python venv if it does not exist. Also ensures that the packages are installed.
# Arguments:
#   Name of the venv.
#   List of packages to install.
#######################################
function ensure_venv() {
    if ! [ -d "$HOME/.venvs/$1" ]; then
        pushd ~/.venvs || return 1

        python3 -m venv "$1"

        popd || return 1
    fi

    # shellcheck source=/dev/null
    source "$HOME/.venvs/$1/bin/activate"

    python3 -m pip install --upgrade "${@:2}"

    deactivate
}

#######################################
# Ensures that a given line is in a file. If not present, it will be added to the end.
# Arguments:
#   The file to check.
#   The line to check/add.
#######################################
function ensure_line() {
    escaped="$(printf '%s' "$2" | sed 's/[.[\*^$]/\\&/g')"
    if grep -q "^$escaped\$" "$1"; then
        return 0
    fi

    echo "$2" >>"$1"
}

sudo apt update
sudo apt upgrade

touch ~/.hushlogin

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
# shellcheck source=/dev/null
source ~/.nvm/nvm.sh
nvm install 22

# Bun
if ! command -v bun; then
    curl -fsSL https://bun.sh/install | bash
fi

# Go
# rm -rf /usr/local/go
if ! [ -d "/usr/local/go" ]; then
    curl -LO https://go.dev/dl/go1.23.4.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz
fi
ensure_line ~/.profile "export PATH=\$PATH:/usr/local/go/bin"

# Neovim
nvim_path=~/bin/nvim
if ! [ -f $nvim_path ]; then
    curl --output-dir "$SCRIPT_DIR" -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    mv -f "$SCRIPT_DIR/nvim.appimage" $nvim_path
    chmod u+x $nvim_path
fi

# Setup python venvs
mkdir ~/.venvs
pkg python3-pip python3-venv

ensure_venv py3nvim \
    pynvim

# LazyVim deps
pkg clang fd-find fzf chafa ripgrep cargo

pkg lua5.1 luarocks
ensure_luarock tiktoken_core

pkg perl
if ! command -v cpanm; then
    curl -L https://cpanmin.us | perl - --sudo App::cpanminus
fi
sudo cpanm -n Neovim::Ext

pkg ruby ruby-dev
sudo gem install neovim

npm install -g neovim prettier

# Fonts
install_font https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/ProggyClean.zip
install_font https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Gohu.zip

# Terminals
# Note that you do not typlically want to run the terminal inside WSL.
if ! [ -v WSL_DISTRO_NAME ]; then
    pkg alacritty
fi

# LazyGit
if ! command -v lazygit; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit -D -t ~/bin/
fi

# Chrome
if ! command -v google-chrome; then
    curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    pkg ./google-chrome-stable_current_amd64.deb
fi

# Stow
pkg stow
pushd ~/.dotfiles || exit
stow nvim
stow alacritty
popd || exit

popd || exit
