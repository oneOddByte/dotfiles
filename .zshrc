# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(git)

source $ZSH/oh-my-zsh.sh


export EDITOR=nvim
export VISUAL=nvim

# Add these lines to your ~/.bashrc or ~/.zshrc
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Optional: Load completions
if command -v pyenv 1>/dev/null 2>&1; then
  autoload -Uz compinit
  compinit
  eval "$(pyenv completions zsh)"
fi


export QT_QPA_PLATFORM=wayland
export PATH=$PATH:/usr/local/go/bin
export PATH="$HOME/go/bin:$PATH"

export CXXFLAGS="-I$HOME/utils"

alias sus="systemctl suspend"
alias off="sudo poweroff"
alias rmp="rm"
alias rm="trash-put"

alias claer="clear"
alias cleawr="clear"
alias clr="clear"
alias clar="clear"
alias clea="clear"

alias zshconf="nvim ~/.zshrc"
alias conf="cd ~/.dotfiles/nvim"
alias dots="cd ~/.dotfiles"
alias q="exit"

alias dev="cd ~/Dev"
alias notes="cd ~/Dev/notes"
alias clg="cd ~/College/"
alias Krish="cd ~/Krish"

alias vi="nvim"
alias ta="tmux a"

alias tmux-save='tmux run-shell ~/.config/tmux/plugins/tmux-resurrect/scripts/save.sh'
alias tmux-save2="tmux run-shell ~/.config/tmux/plugins/tmux-continuum/scripts/continuum_save.sh"

alias sio="sioyek"

alias nextwall='awww img "$(find ~/Pictures -type f | shuf -n 1)" --transition-type random --transition-fps 60 & '
alias nextwall2='awww img "$(find ~/Pictures/mountain_landscape/ -type f | shuf -n 1)" --transition-type random --transition-fps 60 & '


# sudo systemctl enable mysql   # only when needed
alias sql="sudo mysql -u root"

# Stop and disable Snap (lazy mode)
alias stopsnap='sudo systemctl stop snapd.service snapd.socket snapd.seeded.service && sudo systemctl mask snapd.service snapd.socket snapd.seeded.service'
alias startsnap='sudo systemctl unmask snapd.service snapd.socket snapd.seeded.service && sudo systemctl start snapd.socket'

alias aas='arm-none-eabi-as'
alias ald='arm-none-eabi-ld'

alias tlpstat='sudo tlp-stat -s -r -t -c -p -e'

alias ftp='lftp'

alias todo='vi ~/tasks/todo.md'
alias idea='vi ~/tasks/idea.md'
alias leet='vi ~/tasks/leet.md'
alias tt='onlyoffice-desktopeditors ~/tt.xlsx'

alias wificon='nmcli device wifi connect'
alias bt='bluetui'

alias fl='sudo focus_lock'

alias cvat='cd /opt/cvat && export CVAT_HOST=localhost && docker-compose up -d'

bindkey -v

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$PATH:/opt/flutter/bin"
export PATH="$HOME/flutter/bin:$PATH"

export PATH="$HOME/.npm-global/bin:$PATH"
export QT_QPA_PLATFORM=wayland

export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=gasp -Dswing.aatext=true -Dsun.java2d.uiScale=1'

eval "$(zoxide init zsh)"
alias cd='z'

export PATH="$HOME/.local/bin:$PATH"
