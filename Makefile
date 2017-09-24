.PHONY: install

install:
	bin/dfm install


.PHONY: sync-notes

upload-notes:
	cp -rf ~/.vim/bundle/vim-notes/misc/notes/user/ ~/Google\ Drive/vim_notes

download-notes:
	cp -rf ~/Google\ Drive/vim_notes ~/.vim/bundle/vim-notes/misc/notes/user/
