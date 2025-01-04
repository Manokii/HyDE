#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# nvm
if pkg_installed nvm
    then

    echo "Adding nvm to .zshrc"
    source /usr/share/nvm/init-nvm.sh

    if command -v node &> /dev/null
        then
        echo "Node already installed, skipping installation..."
    else
        echo "Installing node"
        nvm install 20
        nvm use 20
    fi

    if command -v pnpm &> /dev/null
        then
        echo "PNPM already installed, skipping installation..."
    else 
      echo "Installing PNPM"
      curl -fsSL https://get.pnpm.io/install.sh | sh -
    fi

else
    echo "WARNING: nvm, node, and pnpm not installed..."
fi

if command -v tmux &> /dev/null
    then
    echo "Installing TMUX Plugin Manager"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm || echo "Skipping TMUX Plugin Manager Installation"
    echo "Installing TMUX Plugins"
    sh ~/.tmux/plugins/tpm/scripts/install_plugins.sh
fi


if pkg_installed fzf 
    then
    echo "Installing fzf-git.sh"

    if [ ! -d ~/Scripts ]; then 
      echo "Creating ~/Scripts folder"
      mkdir ~/Scripts
    fi

    curl "https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh" > ~/Scripts/fzf-git.sh
fi

if pkg_installed bob 
    then
    echo "Installing neovim nightly using bob"
    bob use stable

    if [ -d ~/.config/nvim ]; then

      read -p "Install nvim config manokii/nvchad?" -n 1 -r
      echo    # (optional) move to a new line
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        echo "Setting up neovim config"
        rm -rf ~/.config/nvim
        rm -rf ~/.local/share/nvim
        git clone https://github.com/manokii/nvchad ~/.config/nvim
        cd ~/.config/nvim
        git remote remove origin
        git remote add origin git@github.com:Manokii/nvchad.git
      fi
    else
      echo "Neovim config already exists, skipping setup..."
    fi

fi

if pkg_installed git-delta 
    then
    
    echo "Updating git config for delta"
    git config --global core.pager "delta"
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate "true"
    git config --global delta.line-numbers "true"
    git config --global merge.conflictstyle "diff3"
    git config --global diff.colorMoved "default"
fi


if pkg_installed ags-hyprpanel-git
    then
    echo "Setting up hyprpanel"
    hyprpanel useTheme "$HOME/.config/hyprpanel/config.json" || true
fi

if pkg_installed bat
    then
    echo "Setting up bat theme (catppuccin latte)"
    batDir="$(bat --config-dir)/themes"
    mkdir -p "$batDir"
    curl https://raw.githubusercontent.com/catppuccin/bat/refs/heads/main/themes/Catppuccin%20Latte.tmTheme > "$batDir/catpuccin_latte.tmTheme"
    bat cache --build
fi
