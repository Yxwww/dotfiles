## Setup Environment

```bash
./setup.sh
```

## link dotfiles

```bash
./linkdotfiles.sh
```

## setup

### Tmux italic

- [link on medium](https://medium.com/@dubistkomisch/how-to-actually-get-italics-and-true-colour-to-work-in-iterm-tmux-vim-9ebe55ebc2be)
  Steps:

1. `tic -x ./scripts/xterm-256color-italic.terminfo`
2. `tic -x ./scripts/tmux-256color.terminfo`
3. set $TERM in .zshrc to `tmux-256color.terminfo`
4. set tmux.conf

```
set -g default-terminal 'tmux-256color'
set -as terminal-overrides ',xterm*:Tc:sitm=\E[3m'
```

5. configure vimrc

```
let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
set termguicolors
```

optional: for SSH

```
alias ssh='TERM=xterm-256color ssh'
```

### Tig binding:

https://github.com/jonas/tig/wiki/Bindings
