# Edit $ZDOTDIR/.user.zsh to customize HyDE before loading zshrc

#   Overrides 
# unset HYDE_ZSH_NO_PLUGINS # Set to 1 to disable loading of oh-my-zsh plugins, useful if you want to use your zsh plugins system 
# unset HYDE_ZSH_PROMPT # Uncomment to unset/disable loading of prompts from HyDE and let you load your own prompts
# HYDE_ZSH_COMPINIT_CHECK=1 # Set 24 (hours) per compinit security check // lessens startup time
# HYDE_ZSH_OMZ_DEFER=1 # Set to 1 to defer loading of oh-my-zsh plugins ONLY if prompt is already loaded

#  Personal Configs 
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

aurhelper='yay'

#  Aliases 
alias c='clear'                                                        # clear terminal
alias l='eza -lh --icons=auto'                                         # long list
alias ls='eza -1 --icons=auto'                                         # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto'                                       # long list dirs
alias lt='eza --icons=auto --tree'                                     # list folder as tree
alias un='$aurhelper -Rns'                                             # uninstall package
alias up='$aurhelper -Syu'                                             # update system/package/aur
alias pl='$aurhelper -Qs'                                              # list installed package
alias pa='$aurhelper -Ss'                                              # list available package
alias pc='$aurhelper -Sc'                                              # remove unused cache
alias po='$aurhelper -Qtdq | $aurhelper -Rns -'                        # remove unused packages, also try > $aurhelper -Qqd | $aurhelper -Rsu --print -
alias ssh='kitten ssh'
alias r='source ~/.config/zsh/.zshrc'
alias x='clear'
alias config='cd ~/.config && vim .'
alias zshconfig='vim ~/.config/zsh/.zshrc'
alias q='exit'
alias t='tmux new-session -A -s'
alias repos='cd ~/Repos'
alias undogit='git reset --soft HEAD~1'
alias cleanbranches='git branch --merged | grep -Ev "(^\*|^\+|master|main|staging|dev)" | xargs --no-run-if-empty git branch -d'
alias cleantsconfig="sed -i -r '/^[ \t]*\//d; /^[[:space:]]*$/d; s/\/\*(.*?)\*\///g; s/[[:blank:]]+$//' tsconfig.json" 
alias a='git add .'
alias s='git status -s'
alias c='git commit'
alias g='git log --oneline --graph --decorate'
alias gl='git log --oneline --decorate --reverse'
alias gd='git branch --no-color | fzf -m | xargs -I {} git branch -D '{}''
alias gcane='git commit --amend --no-edit'
alias agcane='a && git commit --amend --no-edit'
alias gpf='git push --force-with-lease'
alias gch='git checkout HEAD'
alias ds='systemctl start docker'
alias dkill='sudo docker kill $(sudo docker ps -q)'
alias ld='sudo lazydocker'
alias pip='pyenv exec pip'
alias python='pyenv exec python'
alias mkdir='mkdir -p'
alias ck_ngrok='ngrok http --url=oryx-whole-bobcat.ngrok-free.app 6969'
alias reset_db='sudo docker container kill postgres-rally && sudo docker container rm postgres-rally && sudo docker run --name postgres-rally -e POSTGRES_PASSWORD=xxxxxxxx -p 5431:5432 -d postgres'
alias restart_db='sudo docker container kill postgres-rally && sudo docker container start postgres-rally'

eval "$(fzf --zsh)"
eval "$(zoxide init zsh --cmd cd)"

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
    cp -r ~/.config/hypr/userprefs.conf ~/.config/hypr/device-config ~/HyDE/Configs/.config/hypr
    cp ~/.config/kitty/userprefs.conf ~/HyDE/Configs/.config/kitty/
    cp ~/.config/hyde/config.toml ~/HyDE/Configs/.config/hyde/
    cp -r ~/.config/ghostty/* ~/HyDE/Configs/.config/ghostty/
    cp ~/.config/hyprpanel/config.json ~/HyDE/Configs/.config/hyprpanel/
    cp ~/.config/tmux/tmux.conf ~/HyDE/Configs/.config/tmux/
    cp ~/.config/zsh/.zshrc ~/HyDE/Configs/.config/zsh/
} 

function cheatsh() {
    curl cheat.sh/"$1"
}

#  Keybinds 
bindkey '^Y' autosuggest-accept
bindkey '^ ' forward-word
bindkey '^W' backward-kill-word

#  Secrets 
export USER_ENV="${ZDOTDIR:-$HOME/.config/zsh}/.env"
if [[ -f "$USER_ENV" ]]; then
    source "$USER_ENV"
fi

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

# The next lines enables shell command completion for Stripe
fpath=(~/.stripe $fpath)
autoload -Uz compinit && compinit -i
