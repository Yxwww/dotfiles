.PHONY: install

install:
	ln -s .vimrc ~/.vimrc
	ln -s .spacemacs ~/.spacemacs
	ln -s .tmux.conf ~/.tmux.conf

uninstall: 
	rm ~/.vimrc
	rm ~/.spacemacs
	rm ~/.tmux.conf

