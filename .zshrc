# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"
#ZSH_THEME="nebirhos"

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

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh
source ~/dev/utils/google-cloud-sdk/path.zsh.inc
source ~/dev/utils/google-cloud-sdk/completion.zsh.inc

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

plugins=(git colored-man colorize github jira vagrant virtualenv pip python brew osx zsh-syntax-highlighting)

JIRA_RAPID_BOARD=true
export ZSH=~/.oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Add env.sh
#source ~/Projects/config/env.sh

# PATH
export PATH=/usr/local/bin:/usr/local/sbin:$PATH

# Vim config
if type nvim > /dev/null 2>&1; then
  alias vim="nvim"
fi
alias vi="vim"
alias ctags="`brew --prefix`/bin/ctags"

#git auto conmpletion
#source ~/.git-completion.bash
#GIT_PS1_SHOWDIRTYSTATE=true
#export PS1='[\u@mbp \w$(__git_ps1)]\$ '

BASE16_SHELL=$HOME/.config/base16-shell/
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

base16_tomorrow-night
alias tmux="TERM=screen-256color-bce tmux"

. $HOME/.shellrc.load

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/yx/dev/utils/google-cloud-sdk/path.zsh.inc' ]; then source '/Users/yx/dev/utils/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/yx/dev/utils/google-cloud-sdk/completion.zsh.inc' ]; then source '/Users/yx/dev/utils/google-cloud-sdk/completion.zsh.inc'; fi
alias tmux="TERM=screen-256color-bce tmux"

# export PATH="/Users/yx/anaconda/bin:$PATH"
# export PYTHONPATH="/Users/Yx/anaconda/bin:/Users/Yx/git/python_symlinks"


# zsh ag config
# Ensure user-installed binaries take precedence
export PATH=/usr/local/bin:$PATH
#
# fzf via Homebrew
if [ -e /usr/local/opt/fzf/shell/completion.zsh ]; then
  source /usr/local/opt/fzf/shell/key-bindings.zsh
  source /usr/local/opt/fzf/shell/completion.zsh
fi

# fzf via local installation
if [ -e ~/.fzf ]; then
  _append_to_path ~/.fzf/bin
  source ~/.fzf/shell/key-bindings.zsh
  source ~/.fzf/shell/completion.zsh
fi

# fzf + ag configuration
if type fzf && type ag; then
  echo 'fzf & ag exists'
  export FZF_DEFAULT_COMMAND='ag --path-to-ignore ~/.ignore --hidden -g ""'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_DEFAULT_OPTS='
  --color fg:242,bg:236,hl:65,fg+:15,bg+:239,hl+:108
  --color info:108,prompt:109,spinner:108,pointer:168,marker:168
  '
fi


# Source bash_profile
source ~/.bash_profile

# Settle python and pip (hopefully)
alias pip='python2 -m pip'
alias pip3='python3 -m pip'
