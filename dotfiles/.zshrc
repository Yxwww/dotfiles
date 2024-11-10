# profiling tool: https://esham.io/2018/02/zsh-profiling
ENABLE_ZSH_PROFILING=false
if [ "$ENABLE_ZSH_PROFILING" = true ] ; then
  zmodload zsh/datetime
  setopt PROMPT_SUBST
  PS4='+$EPOCHREALTIME %N:%i> '

  logfile=$(mktemp zsh_profile.XXXXXXXX)
  echo "Logging to $logfile"
  exec 3>&2 2>$logfile

  setopt XTRACE
fi


## zsh-autocomplete

## MARK: Vim Mode Config
# enable vim mode
bindkey -v

# Yank to the system clipboard
function vi-yank-xclip {
    zle vi-yank
   echo "$CUTBUFFER" | pbcopy -i
}
zle -N vi-yank-xclip
bindkey -M vicmd 'y' vi-yank-xclip

# Make Vi mode transitions faster (KEYTIMEOUT is in hundredths of a second)
export KEYTIMEOUT=1
bindkey "^?" backward-delete-char
bindkey "^W" backward-kill-word
bindkey "^H" backward-delete-char      # Control-h also deletes the previous char
bindkey "^U" backward-kill-line


## fzf git completion
function _gcof {
  git recent | fzf | xargs git checkout
}
# fbr - checkout git branch (including remote branches), sorted by most recent commit, limit 30 last branches
fbr() {
  local branches branch
  branches=$(git for-each-ref --count=100 --sort=-committerdate refs/heads/ --format="%(refname:short)") &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}
# fco - checkout git branch/tag
fco() {
  local tags branches target branchname
  branches=$(
    git --no-pager branch --all --sort=-committerdate \
      --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
    | sed '/^$/d') || return
  tags=$(
    git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}') || return
  target=$(
    (echo "$branches"; echo "$tags") |
    fzf --no-hscroll --no-multi -n 2 \
        --ansi) || return

  branchname=$(awk '{print $2}' <<<"$target" )
  withoutOrigin=${branchname/origin\//}
  echo "switching to $withoutOrigin  💵"
  git checkout "$withoutOrigin"
}
zle -N fco
bindkey "^x^o" fco

viewPR() {
  local pr_number pr_title
  pr_info=$(gh pr list | fzf --preview "gh pr view {+1} | bat --color=always --style=plain --language=markdown")
  pr_number=$(echo "$pr_info" | awk '{print $1}')
  pr_title=$(echo "$pr_info" | cut -d' ' -f2-)
  if [ -n "$pr_number" ]; then
    echo "Switching to PR #$pr_number:\nTitle: \"$pr_title\""
    (
      echo -n "Opening PR in browser... "
      spinner() {
        local pid=$1
        local delay=0.1
        local spinstr='|/-\'
        while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
          local temp=${spinstr#?}
          printf " [%c]  " "$spinstr"
          local spinstr=$temp${spinstr%"$temp"}
          sleep $delay
          printf "\b\b\b\b\b\b"
        done
        printf "    \b\b\b\b"
      }
      gh pr checkout "$pr_number" && (gh pr view "$pr_number" --web &) &
      spinner $!
      echo "Done!"
    )
  fi
}
zle -N viewPR
bindkey "^x^p" viewPR



# Updates editor information when the keymap changes.
function zle-keymap-select() {
  zle reset-prompt
  zle -R
}

zle -N zle-keymap-select
## MARK: THEME CONFIG
#

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
# export ZSH=~/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# BASE16_SHELL="$HOME/.config/base16-shell/"
# [ -n "$PS1" ] && \
#     [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
#         eval "$("$BASE16_SHELL/profile_helper.sh")"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# source $ZSH/oh-my-zsh.sh
# source ~/dev/utils/google-cloud-sdk/path.zsh.inc
# source ~/dev/utils/google-cloud-sdk/completion.zsh.inc

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

#ZSH_THEME=pygmalion

plugins=(git, fzf)

# Add env.sh
#source ~/Projects/config/env.sh

# PATH
export PATH=/usr/local/bin:/usr/local/sbin:$PATH

# Vim config
if type nvim > /dev/null 2>&1; then
  alias vim="nvim"
elif type mvim > /dev/null 2>&1; then
  alias vim="mvim -v"
fi


alias zellijsimple="zellij --layout ~/git/dotfiles/configs/zellij/layouts/base.kdl"
alias zellijvs="zellij --layout ~/git/dotfiles/configs/zellij/layouts/vscodeterm.kdl"
alias zellijstd="zellij --layout ~/git/dotfiles/configs/zellij/layouts/standard3.kdl"

alias vi="vim"

# zsh ag config
# Ensure user-installed binaries take precedence
export PATH=/usr/local/bin:$PATH
#
# fzf via Homebrew
if [ -e /usr/local/opt/fzf/shell/completion.zsh ]; then
  source /usr/local/opt/fzf/shell/key-bindings.zsh
  source /usr/local/opt/fzf/shell/completion.zsh
fi

# fzf + ag configuration
if type fzf &> /dev/null && type rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files --no-ignore-vcs --hidden'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_DEFAULT_OPTS='
  --color fg:242,bg:236,hl:65,fg+:15,bg+:239,hl+:108
  --color info:108,prompt:109,spinner:108,pointer:168,marker:168
  '
fi

# fzf search through file contents using rg
fzf_search_contents() {
  local file
  file=$(rg --color=always --line-number --no-heading --smart-case "${*:-}" |
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --delimiter : \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind 'enter:become(vim {1} +{2})')
}
zle -N fzf_search_contents
bindkey '^x^g' fzf_search_contents

# Deps
source ~/.bashrc
source ~/.bash_profile

# Set Spaceship ZSH as a prompt
autoload -U promptinit; promptinit

# base16_onedark
test -r "~/.dir_colors" && eval $(dircolors ~/.dir_colors)

export BAT_THEME='Nord'

# zsh config
setopt auto_cd

# richer file/dir name auto complete
zstyle ':completion:*' completer _complete
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|=* r:|=*'
autoload -Uz compinit
compinit
source ~/.zshrc_fnm

bindkey '^[[Z' reverse-menu-complete # make Shift-tab go to previous completion

autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "\e[A" history-beginning-search-backward-end  # cursor up
bindkey "\e[B" history-beginning-search-forward-end   # cursor down

# clipper config
alias clip="nc -U ~/.clipper.sock"
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=180'
bindkey '^o' autosuggest-clear

# MARK: ZSH completions
fpath=(~/.zsh/zsh-completions/src $fpath)

# MARK: ls coloring, requires `ls -G` G flag enabled.
LS_COLORS=""
export LS_COLORS
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# for VIM and TMUC
if [ "$TERM" = "xterm" ]; then
  export TERM=xterm-256color-italic
fi

# Enable debug
# zprof

# handles LSOpenURLsWithRole() failed with error -600 for th
# https://apple.stackexchange.com/questions/167753/lsopenurlswithrole-failed-with-error-10810-in-iterm2-running-tmux-on-yosemite?rq=1
alias open='reattach-to-user-namespace open'
export MYVIMRC=~/.vimrc
export EDITOR='nvim'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# profiling uncomnment next 2 lines
#
if [ "$ENABLE_ZSH_PROFILING" = true ] ; then
  unsetopt XTRACE
  exec 2>&3 3>&-
fi


export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export PATH="$HOME/.deno/bin:$PATH"

export MANPAGER="sh -c 'col -bx | bat -l man -p'"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PNPM_HOME="/Users/yuxiwang/Library/pnpmnk"
export PATH="$PNPM_HOME:$PATH"


eval "$(fnm env)"
fpath+=~/.config/zsh/completions/_fnm
fpath+=~/.config/zsh/completions/_gh
compinit

eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"

source ~/.zshrc_profile


# pnpm
export PNPM_HOME="/Users/yuxiwang/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
source ~/.zshrc_extra
# . "/Users/yuxiwang/.deno/env"
