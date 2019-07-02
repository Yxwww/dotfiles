#!/bin/bash

# setup spaceship-prompt https://github.com/denysdovhan/spaceship-prompt
# Faster startup than oh-my-zsh: 70ms vs 400ms
setup_zsh_spaceship() {
  brew install zsh
  yarn global add spaceship-prompt
  git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
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
  brew install ctags
  brew install ninja

  ## Setup llvm+clang & ccls follows https://github.com/MaskRay/ccls/wiki/Build step by step

  ## SYSTEM HEADER SETUP on OSX :
  ## 1. if missing system headers run: open /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14. pkg

  ## 2. Use shell script wrapper to wrap ccls to explicitly use the correct CommandLineTools c++ lib instead of the default one
  ## to provide proper c++ lib linting support: https://github.com/MaskRay/ccls/issues/191#issuecomment-453809905
  #!/bin/sh
  #exec /path/to/ccls/Release/ccls -init='{"clang":{"extraArgs":["-isystem", "/Library/Developer/CommandLineTools/usr/include/c++/v1"]}}' "$@"
  ##
}

install_eslint_prettier() {
  yarn global install eslint prettier
  cd ~ && yarn
}

