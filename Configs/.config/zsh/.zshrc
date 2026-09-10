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
# alias ssh='kitten ssh'
alias r='source ~/.config/zsh/.zshrc'
alias x='clear'
alias config='cd ~/.config && nvim ~/.config/hypr/userprefs.conf'
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
alias ld='sudo lazydocker'
alias pip='pyenv exec pip'
alias python='pyenv exec python'
alias mkdir='mkdir -p'
alias ck_ngrok='ngrok http --url=oryx-whole-bobcat.ngrok-free.app 6969'
alias wkeys='wshowkeys -F "JetbrainsMono Nerd Font" -a bottom -a right &'
alias killwkeys='pkill wshowkeys'
alias unstage='git restore --staged .'
alias xedge_on='hyprctl dispatch dpms on HDMI-A-1'
alias xedge_off='hyprctl dispatch dpms off HDMI-A-1'
alias mv_stl='mv --verbose --force ~/Downloads/*.{stl,3mf} ~/Documents/3d\ prints/'
alias gwa="git worktree add"
alias gwl="git worktree list"
alias gwr="git worktree remove"
alias ch="cd ~/claude-home/ && claude"
# for running commands on background
# nohup _____ > ~/.temp/FILE_NAME_HERE 2>&1 & 

(( $+commands[fzf] )) && eval "$(fzf --zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"

function hyprxedge_restart() {
  ags quit -i hyprxedge;
  nohup ags run /home/manok/repos/hyprxedge &

}

function db_select() {

  is_active=$(sudo systemctl is-active docker)

  if [[ $is_active != "active" ]]; then
    sudo systemctl start docker
  fi

  selected_db=$(for key in "${(@k)db_list}"; do
    echo "$key"
  done | fzf)

  if [[ -n "$selected_db" ]]; then
    echo "$selected_db"
  else
    echo "No database selected."
    exit 1
  fi
}

function docker_close() {
  sudo sh -c 'docker stop $(docker ps -a -q)'
}

function gwc() {
    local selected_worktree=$(git worktree list | fzf --height 40% --reverse --header "Select Git Worktree" | awk '{print $1}')

    # 3. If a selection was made (not escaped/cancelled), cd into it
    if [ -n "$selected_worktree" ]; then
        cd "$selected_worktree" || return
        echo "Switched to: $(pwd)"
    else
        echo "No worktree selected."
    fi
}


function tmux_amp() {
    # systemctl start docker
    cd ~/repos/campainless-monorepo/
    local SESSION_NAME="american-majority-project"

    # --- Window 1: Coding  ---
    local W1_NAME="coding"
    local W1_CMD1="nvim ."

    # --- Window 1: Dev terminals ---
    local W2_NAME='terminals'
    local W2_CMD1="bun run dev db:studio"

    pgrep -f docker > /dev/null || systemctl start docker
    sudo sh -c 'docker stop $(docker ps -a -q) && bun run db:start'

    # Check if the tmux session already exists
    tmux has-session -t $SESSION_NAME 2>/dev/null

    # $? is a special variable that holds the exit code of the last command.
    # If the session does not exist, tmux has-session returns a non-zero exit code.
    if [ $? != 0 ]; then
        echo "Creating new tmux session: $SESSION_NAME"

        # Start a new detached tmux session and name the first window
        tmux new-session -s $SESSION_NAME -d -n $W1_NAME 

        # INFO: USE YOUR CONFIGURED pane-base-index in tmux.conf

        # --- Setup Window 1: Coding ---

        # --- Setup Window 2: Dev processes ---
        tmux new-window -n $W2_NAME -t $SESSION_NAME

        # - Commands
        tmux send-keys -t $SESSION_NAME:$W1_NAME.1 "$W1_CMD1" C-m
        tmux send-keys -t $SESSION_NAME:$W2_NAME.1 "$W2_CMD1" C-m

        # Select the second window to be active
        tmux select-window -t $SESSION_NAME:$W1_NAME
    fi

    echo "Attaching to tmux session: $SESSION_NAME"
    # Attach to the session
    tmux attach-session -t $SESSION_NAME
}

function tmux_womo() {
    # systemctl start docker
    cd ~/repos/womo
    gwc
    local SESSION_NAME="attr"

    # --- Window 1: Coding  ---
    local W1_NAME="coding"
    local W1_CMD1="nvim ."

    # --- Window 1: Dev terminals ---
    local W2_NAME='terminals'
    local W2_CMD1="bun run dev db:studio"

    # Pre ritual
    pgrep -f docker > /dev/null || systemctl start docker
    sudo sh -c 'docker stop $(docker ps -a -q) && bun run db:start'

    # Check if the tmux session already exists
    tmux has-session -t $SESSION_NAME 2>/dev/null

    # $? is a special variable that holds the exit code of the last command.
    # If the session does not exist, tmux has-session returns a non-zero exit code.
    if [ $? != 0 ]; then
        echo "Creating new tmux session: $SESSION_NAME"

        # Start a new detached tmux session and name the first window
        tmux new-session -s $SESSION_NAME -d -n $W1_NAME 

        # INFO: USE YOUR CONFIGURED pane-base-index in tmux.conf

        # --- Setup Window 1: Coding ---
        tmux send-keys -t $SESSION_NAME:$W1_NAME.1 "$W1_CMD1" C-m

        # --- Setup Window 2: Dev processes ---
        tmux new-window -n $W2_NAME -t $SESSION_NAME

        # - Commands
        tmux send-keys -t $SESSION_NAME:$W2_NAME.1 "$W2_CMD1" C-m
        tmux send-keys -t $SESSION_NAME:$W2_NAME.2 "$W2_CMD2" C-m

        tmux select-layout -t $SESSION_NAME:$W2_NAME tiled


        # Select the second window to be active
        tmux select-window -t $SESSION_NAME:$W1_NAME
    fi

    echo "Attaching to tmux session: $SESSION_NAME"
    # Attach to the session
    tmux attach-session -t $SESSION_NAME
}

function tmux_closer() {
    # systemctl start docker
    cd ~/repos/closer
    local SESSION_NAME="closer"

    # --- Window 1: Dev processes (4 panes) ---
    local W1_NAME='processes'
    local W1_CMD1="bun run stripe:dev"
    local W1_CMD2="ngrok http --url=lily-nonglandulous-machelle.ngrok-free.dev 3000"
    local W1_CMD3="bun run db:studio"
    local W1_CMD4="bun run dev"                  # Example: open a code editor

    # --- Window 2: Coding (2 panes) ---
    local W2_NAME="coding"
    local W2_CMD1="nvim ."

    # Pre ritual
    pgrep -f docker > /dev/null || sudo systemctl start docker
    sudo sh -c 'docker stop $(docker ps -a -q) && bun run db:start'

    # Check if the tmux session already exists
    tmux has-session -t $SESSION_NAME 2>/dev/null

    # $? is a special variable that holds the exit code of the last command.
    # If the session does not exist, tmux has-session returns a non-zero exit code.
    if [ $? != 0 ]; then
        echo "Creating new tmux session: $SESSION_NAME"

        # Start a new detached tmux session and name the first window
        tmux new-session -s $SESSION_NAME -d -n $W1_NAME

        # REMINDER: USE YOUR CONFIGURED pane-base-index in tmux.conf

        # --- Setup Window 1: Dev processes ---
        tmux split-window -v -t $SESSION_NAME:$W1_NAME.1
        tmux split-window -h -t $SESSION_NAME:$W1_NAME.1
        tmux split-window -h -t $SESSION_NAME:$W1_NAME.2
        tmux send-keys -t $SESSION_NAME:$W1_NAME.1 "$W1_CMD1" C-m
        tmux send-keys -t $SESSION_NAME:$W1_NAME.2 "$W1_CMD2" C-m
        tmux send-keys -t $SESSION_NAME:$W1_NAME.3 "$W1_CMD3" C-m
        tmux send-keys -t $SESSION_NAME:$W1_NAME.4 "$W1_CMD4" C-m
        tmux select-layout -t $SESSION_NAME:$W1_NAME tiled

        # --- Setup Window 2: Coding ---
        tmux new-window -n $W2_NAME -t $SESSION_NAME
        tmux send-keys -t $SESSION_NAME:$W2_NAME.1 "$W2_CMD1" C-m
        # tmux split-window -h -t $SESSION_NAME:$W2_NAME.0
        # tmux send-keys -t $SESSION_NAME:$W2_NAME.1 "$W2_CMD2" C-m

        # Select the second window to be active
        tmux select-window -t $SESSION_NAME:$W2_NAME
    fi

    echo "Attaching to tmux session: $SESSION_NAME"
    # Attach to the session
    tmux attach-session -t $SESSION_NAME
}

function db_restart() {
  selected_db=$(db_select)
  db_port=${db_list[${selected_db}]}
  echo "Starting database '$selected_db' on port $db_port..."
  sudo sh -c "
    docker container kill $selected_db > /dev/null \
      && docker container start $selected_db > /dev/null \
      && echo \"Database '$selected_db' has been restarted.\"
  "
}

function db_start() {
  selected_db=$(db_select)
  db_port=${db_list[${selected_db}]}
  echo "Starting database '$selected_db' on port $db_port..."
  sudo sh -c "
    docker container start $selected_db > /dev/null \
      && echo \"Database '$selected_db' has been started.\"
  "
}

function amp_ssh() {
  ssh -i ~/xxx/JasperKeyPair.pem ec2-user@$(aws ec2 describe-instances --instance-ids i-0a2a3f0721dbb8c42 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
}



function venv() {
  DIR=$(basename "$PWD")
  pyenv virtualenv $DIR
  pyenv activate $DIR
}

function activate() {
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
    cp -r ~/.config/caelestia/* ~/HyDE/Configs/.config/caelestia/
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

# bun completions
[ -s "/home/manok/.bun/_bun" ] && source "/home/manok/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
if [ -d "$BUN_INSTALL" ]; then
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

. "$HOME/.local/share/../bin/env"

export PATH="/home/manok/.devcontainers/bin:$PATH"


<<<<<<< Updated upstream
#  This is your file 
# Add your configurations here
# export EDITOR=nvim
# export EDITOR=code
||||||| Stash base
#  This is your file 
# Add your configurations here
# export EDITOR=nvim
export EDITOR=code
=======
>>>>>>> Stashed changes

