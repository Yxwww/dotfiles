# link dotfiles to ~/
ln -sf "$(pwd)"/dotfiles/{*,.[^.],.??*} ~/

CONFIG_HOME=~
GHOSTTY_CONFIG=$CONFIG_HOME/ghostty/config
# git ignore
CONFIG_DIR=~/.config
GIT_CONFIG_DIR=$CONFIG_DIR/git
mkdir -p $GIT_CONFIG_DIR

ln -snf "$(pwd)"/configs/ghostty $CONFIG_DIR

ln -sf "$(pwd)"/configs/git/ignore $GIT_CONFIG_DIR/

# zed
ln -snf "$(pwd)"/configs/zed/keymap.json $CONFIG_DIR/zed
ln -snf "$(pwd)"/configs/zed/settings.json $CONFIG_DIR/zed

# nvim
ln -snf "$(pwd)"/configs/nvim ~/.config

# iterm2
ln -snf "$(pwd)"/configs/iterm/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist

# node
# ln -sf "$(pwd)"/configs/node/package.json ~/.config/yarn/global/
# ln -sf "$(pwd)"/configs/node/yarn.lock ~/.config/yarn/global/

# node
# ln -sf "$(pwd)"/configs/node/package.json ~/
# ln -sf "$(pwd)"/configs/node/yarn.lock ~/

# starship
ln -sf "$(pwd)"/configs/starship.toml ~/.config

# code
ln -sf "$(pwd)"/configs/Code/keybindings.json ~/Library/Application\ Support/Code/User/
ln -sf "$(pwd)"/configs/Code/settings.json ~/Library/Application\ Support/Code/User/

if [ -d ~/Library/Application\ Support/Cursor ]; then
  ln -sf "$(pwd)"/configs/Cursor/settings.json ~/Library/Application\ Support/Cursor/User/
else
  echo "Directory ~/Library/Application Support/Cursor/User/ does not exist. Skip cursor config linking"
fi
