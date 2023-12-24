# link dotfiles to ~/
ln -sf "$(pwd)"/dotfiles/{*,.[^.],.??*} ~/

# git ignore
GIT_CONFIG_DIR=~/.config/git
mkdir -p $GIT_CONFIG_DIR
ln -sf "$(pwd)"/configs/git/ignore $GIT_CONFIG_DIR/

# nvim
ln -snf "$(pwd)"/configs/nvim ~/.config/nvim

# iterm2
ln -snf "$(pwd)"/configs/iterm/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist

# node
# ln -sf "$(pwd)"/configs/node/package.json ~/.config/yarn/global/
# ln -sf "$(pwd)"/configs/node/yarn.lock ~/.config/yarn/global/

# node
ln -sf "$(pwd)"/configs/node/package.json ~/
# ln -sf "$(pwd)"/configs/node/yarn.lock ~/

# alacritty
ln -sf "$(pwd)"/configs/alacritty ~/.config

# zellij
ln -sf "$(pwd)"/configs/zellij ~/.config

# starship
ln -sf "$(pwd)"/configs/starship.toml ~/.config

# code
ln -sf "$(pwd)"/configs/Code/keybindings.json ~/Library/Application\ Support/Code/User/
ln -sf "$(pwd)"/configs/Code/settings.json ~/Library/Application\ Support/Code/User/
