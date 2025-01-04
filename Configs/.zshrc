# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Add user configurations here
# For HyDE to not touch your beloved configurations,
# we added 2 files to the project structure:
# 1. ~/.hyde.zshrc - for customizing the shell related hyde configurations
# 2. ~/.zshenv - for updating the zsh environment variables handled by HyDE // this will be modified across updates

#  Plugins 
eval "$(fzf --zsh)"
eval "$(zoxide init zsh --cmd cd)"

export EDITOR='nvim'

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"


export PATH="$PATH:/home/manok/.local/share/bob/nvim-bin"
export BAT_THEME='catpuccin_latte'
export SSH_AUTH_SOCK=~/.1password/agent.sock

_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

#  Aliases 
alias ssh='kitten ssh' \
      r='source ~/.zshrc' \
      x='clear' \
      config='cd ~/.config && vim .' \
      zshconfig='vim ~/.zshrc' \
      q='exit' \
      t='tmux new-session -A -s' \
      repos='cd ~/Repos' \
      undogit='git reset --soft HEAD~1' \
      cleanbranches='git branch --merged | grep -Ev "(^\*|^\+|master|main|staging|dev)" | xargs --no-run-if-empty git branch -d' \
      cleantsconfig="sed -i -r '/^[ \t]*\//d; /^[[:space:]]*$/d; s/\/\*(.*?)\*\///g; s/[[:blank:]]+$//' tsconfig.json" \
      a='git add .' \
      s='git status -s' \
      c='git commit' \
      g='git log --oneline --graph --decorate' \
      gl='git log --oneline --decorate --reverse' \
      gd='git branch --no-color | fzf -m | xargs -I {} git branch -D '{}'' \
      ds='systemctl start docker' \
      dkill='sudo docker kill $(sudo docker ps -q)' \
      ld='sudo lazydocker' \
      mac='ssh $MAC_HOST' \
      l='eza -lha  --icons=auto --sort=name --group-directories-first --no-permissions --no-user' \
      ls='eza -1   --icons=auto' \
      ll='eza -lha --icons=auto --sort=name --group-directories-first' \
      ld='eza -lhD --icons=auto' \
      lt='eza --icons=auto --tree' \
      pip='pyenv exec pip' \
      python='pyenv exec python' 
      # nvim='~/.config/kitty/kitty.sh' 

function venv() {
  DIR=$(basename "$PWD")
  pyenv virtualenv $DIR
  pyenv activate $DIR
}

function act() {
  DIR=$(basename "$PWD")
  pyenv activate $DIR
}

function nowplaying() {
  echo "[$(playerctl metadata xesam:title)]($(playerctl metadata xesam:url))"
}


function np() {
  playerctl metadata xesam:title
}

function npl() {
  playerctl metadata xesam:url
}

function cpconfig() {
    cp ~/.config/hypr/{hyprland,keybindings,userprefs,hyde,monitors,windowrules}.conf ~/HyDE/Configs/.config/hypr/
    cp ~/.config/kitty/userprefs.conf ~/.config/kitty/kitty.conf ~/HyDE/Configs/.config/kitty/
    cp ~/.config/hyprpanel/config.json ~/HyDE/Configs/.config/hyprpanel/
    cp ~/.config/hyde/config.toml ~/HyDE/Configs/.config/hyde/
    cp ~/.config/tmux/tmux.conf ~/HyDE/Configs/.config/tmux/
    cp ~/.zshrc ~/HyDE/Configs/
} 

#  Keybinds 
bindkey '^Y' autosuggest-accept
bindkey '^ ' forward-word
bindkey '^W' backward-kill-word

#  Configs 

# fzf
if [ -f ~/Scripts/fzf-git.sh ]; then
    source ~/Scripts/fzf-git.sh
fi

# Node Version Manager
if [ -f /usr/share/nvm/init-nvm.sh ]; then
    source /usr/share/nvm/init-nvm.sh
fi

if command -v nvim >/dev/null 2>&1; then
    export EDITOR='nvim'
    alias vim='nvim'
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
[[ -d $PYENV_ROOT/bin ]] && eval "$(pyenv init - zsh)"
[[ -d $PYENV_ROOT/bin ]] && eval "$(pyenv virtualenv-init -)"
export VIRTUAL_ENV_DISABLE_PROMPT=1

# pnpm
export PNPM_HOME="/home/manok/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

