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
bindkey "^b" fco

viewPR() {
  gh pr list | fzf --preview "gh pr view {+1}" | awk '{print $1}' | xargs gh pr view --web
}
zle -N viewPR
bindkey "^p" viewPR

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

# Deps
source ~/.bashrc
source ~/.bash_profile

# Set Spaceship ZSH as a prompt
autoload -U promptinit; promptinit

# base16_onedark
test -r "~/.dir_colors" && eval $(dircolors ~/.dir_colors)


# common aliases
# alias l='ls -lFhG'
alias l='exa --classify --all --long --header'
alias cat='bat'
export BAT_THEME='Nord'
alias ls='exa'

# git aliases
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'
alias gav='git add --verbose'
alias gap='git apply'

alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbda='git branch --no-color --merged | command grep -vE "^(\*|\s*(master|develop|dev)\s*$)" | command xargs -n 1 git branch -d'
alias gbD='git branch -D'
alias gbl='git blame -b -w'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
alias gbs='git bisect'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsr='git bisect reset'
alias gbss='git bisect start'

alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gcn!='git commit -v --no-edit --amend'
alias gca='git commit -v -a'
alias gca!='git commit -v -a --amend'
alias gcan!='git commit -v -a --no-edit --amend'
alias gcans!='git commit -v -a -s --no-edit --amend'
alias gcam='git commit -a -m'
alias gcsm='git commit -s -m'
alias gcb='git checkout -b'
alias gcf='git config --list'
alias gcl='git clone --recurse-submodules'
alias gclean='git clean -fd'
alias gpristine='git reset --hard && git clean -dfx'
alias gcm='git checkout master'
alias gcd='git checkout develop'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gcof='git cofzf'
alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gcs='git commit -S'

alias gd='git diff'
alias gdca='git diff --cached'
alias gdcw='git diff --cached --word-diff'
alias gdct='git describe --tags `git rev-list --tags --max-count=1`'
alias gds='git diff --staged'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gdw='git diff --word-diff'

alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gfo='git fetch origin'

alias grh='git reset'
alias grhh='git reset --hard'

alias gst='git status'
alias gui='gitui'
alias gsta='git stash save'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --text'
alias gstall='git stash --all'
alias gsu='git submodule update'

alias gts='git tag -s'
alias gtv='git tag | sort -V'


# zsh config
setopt auto_cd

# richer file/dir name auto complete
zstyle ':completion:*' completer _complete
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|=* r:|=*'
autoload -Uz compinit
compinit

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
LS_COLORS="di=34;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=31;40:cd=31;40:su=31;40:sg=31;40:tw=31;40:ow=31;40:"
export LS_COLORS
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# for VIM and TMUC
if [ "$TERM" = "xterm" ]; then
  export TERM=xterm-256color-italic
fi
alias yanr='yarn'  # yeah ...

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

alias ifconfigdefault='ipconfig getifaddr en0'

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

source ~/.zshrc_profile

# pnpm
export PNPM_HOME="/Users/yuxiwang/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
source ~/.zshrc_extra
