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


setup_zsh_autosuggestions() {
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
}

setup_cpp_dev() {
  ln -sf ./configs/coc-settings.json ~/.vim/
  brew install ccls
  brew install ctags
  # if missing system headers run: open /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14. pkg
}
