#!/bin/bash
echo "Brew setup with yarn"
brew install yarn

echo "Setup nvim"
brew install neovim
yarn global add neovim

echo "link dotfiles"
./godotfiles -force
