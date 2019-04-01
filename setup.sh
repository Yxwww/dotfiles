#!/bin/bash

# setup spaceship-prompt https://github.com/denysdovhan/spaceship-prompt
# Faster startup than oh-my-zsh: 70ms vs 400ms
setup_zsh_spaceship() {
  brew install zsh
  yarn global add spaceship-prompt
}

setup_js() {
  brew install yarn
}

# echo "Setup nvim"
setup_neovim() {
  brew install neovim
  yarn global add neovim
}

# echo "link dotfiles"
link_dotfiles() {
  ./linkdotfiles.sh
}


# Tmux setup
## Clipper setup
setup_clipper() {
  brew install clipper
  brew services start clipper
}

