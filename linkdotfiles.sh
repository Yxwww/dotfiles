# link dotfiles to ~/
ln -sf "$(pwd)"/dotfiles/{*,.[^.],.??*} ~/

# git ignore
GIT_CONFIG_DIR=~/.config/git
mkdir -p $GIT_CONFIG_DIR
ln -sf "$(pwd)"/configs/git/ignore $GIT_CONFIG_DIR/

# coc-settings
ln -sf "$(pwd)"/configs/vim/coc-settings.json ~/.config/nvim/

# vim deps
ln -snf "$(pwd)"/configs/vim/config ~/.vim/config
ln -snf "$(pwd)"/configs/vim/ftplugin ~/.vim/ftplugin
