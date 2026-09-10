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

    read -p "Install Neovim using bob?" -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      echo "Installing neovim using bob"
      bob use stable
    fi


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

# symlink device config
# Don't use $HOST: it's a zsh-only variable and is empty under bash (this script runs
# with #!/usr/bin/env bash). bash sets $HOSTNAME; fall back to /etc/hostname (set by
# systemd) since the `hostname` binary isn't installed on minimal Arch.
deviceHost="${HOSTNAME:-$(cat /etc/hostname 2>/dev/null)}"
echo "Checking for device config for $deviceHost"
if [ -f "$HOME/.config/hypr/device-config/device-$deviceHost.conf" ]; then
    echo "Symlinking device config for $deviceHost"
    rm "$HOME/.config/hypr/device-config/current.conf" && ln -s "$HOME/.config/hypr/device-config/device-$deviceHost.conf" "$HOME/.config/hypr/device-config/current.conf" 2> /dev/null || true
  else
    echo "No device config found for $deviceHost, skipping symlink..."
fi

# caelestia custom color schemes
# caelestia-cli ships its built-in schemes inside the package data dir. Our custom
# schemes live in ~/.config/caelestia/schemes and must be copied alongside them so
# the shell/CLI can discover and switch to them.
if pkg_installed caelestia-cli
    then
    cae_schemes_src="${HOME}/.config/caelestia/schemes"

    if [ -d "${cae_schemes_src}" ]; then
        cae_data_schemes=$(ls -d /usr/lib/python3.*/site-packages/caelestia/data/schemes 2>/dev/null | head -1)
        [ -z "${cae_data_schemes}" ] && cae_data_schemes="/usr/lib/python3.14/site-packages/caelestia/data/schemes"

        echo "Installing caelestia custom schemes to ${cae_data_schemes}"
        sudo mkdir -p "${cae_data_schemes}"
        sudo cp -rf "${cae_schemes_src}/." "${cae_data_schemes}/"
    else
        echo "No caelestia custom schemes found at ${cae_schemes_src}, skipping..."
    fi
fi

# AMD-only systems: fix SDDM black-screen / GPU-not-loaded race at boot.
# - mkinitcpio defaults to MODULES=() and relies on the `kms` hook to autodetect amdgpu.
#   That race occasionally loses to systemd, leaving the system on simpledrm (slow,
#   black SDDM). Forcing amdgpu into the initramfs eliminates the race.
# - hyprland/libglvnd/steam pull in nvidia-utils as a hard dependency, which ships
#   /usr/lib/modules-load.d/nvidia-utils.conf attempting to load nvidia_uvm at boot.
#   On AMD-only boxes this errors. Masking it with an empty override silences it.
if lspci | grep -qE '(VGA|3D|Display).*AMD/ATI' && ! lspci | grep -qE '(VGA|3D|Display).*NVIDIA'
    then
    echo "[AMDGPU] AMD-only GPU detected, checking SDDM black-screen fixes..."

    rebuild_initramfs=0

    if [ -f /usr/lib/modules-load.d/nvidia-utils.conf ] && [ ! -f /etc/modules-load.d/nvidia-utils.conf ]; then
        echo "[AMDGPU] Masking nvidia-utils modules-load.d (nvidia-utils is pulled in as a hyprland dep but unused on AMD)"
        sudo install -m 644 /dev/null /etc/modules-load.d/nvidia-utils.conf
    fi

    if grep -q '^MODULES=()' /etc/mkinitcpio.conf; then
        echo "[AMDGPU] Adding amdgpu to mkinitcpio MODULES for early-load"
        sudo sed -i 's/^MODULES=()/MODULES=(amdgpu)/' /etc/mkinitcpio.conf
        rebuild_initramfs=1
    fi

    if [ "$rebuild_initramfs" -eq 1 ]; then
        echo "[AMDGPU] Rebuilding initramfs..."
        sudo mkinitcpio -P
    else
        echo "[AMDGPU] No changes needed."
    fi
fi

# AMD iGPU + NVIDIA dGPU hybrid laptops (ROG Flow X13 2023, G14, etc.)
"${scrDir}/install_pst_amd_nvidia.sh"
