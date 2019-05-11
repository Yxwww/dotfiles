# link dotfiles to ~/
ln -sf "$(pwd)"/dotfiles/{*,.[^.],.??*} ~/

# git ignore
GIT_CONFIG_DIR=~/.config/git
mkdir -p $GIT_CONFIG_DIR
ln -sf "$(pwd)"/configs/git/ignore $GIT_CONFIG_DIR/
