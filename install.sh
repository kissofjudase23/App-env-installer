#!/bin/bash
# author: Tom_Lin
# date:   2015/12/2

#include common functions
. ./script_funcs.sh


#this function is dupracted now.
depracted_code() {
# For. bashrc
# create a symbolic link to config script.
chmod +x "e23_config.sh"
ln -s $(pwd)/e23_config.sh ~/e23_config_symbolic

LINE='source ~/e23_config_symbolic'
FILE=.bashrc
cd ~

# check .bashrc and create if necessary.
Check_File_and_Create $FILE

# add a entry porint to user-defined script in .bashrc.
# add LINE to FILE only if this LINE dose not exists.
grep -q "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

# For .vimrc
# check .bashrc and delete if necessary.
FILE=.vimrc
Check_File_and_Delete $FILE

cd - 
# create a symbolic for user-defined .vimrc
ln -s $(pwd)/$FILE ~/$FILE

}


backup_dotfiles() {

	#clean backup folder
	rm -rf ${BK_DIR}/*
	mkdir -p ${BK_DIR}/

	cd ${BK_DIR}
	for file in "${FILE_LIST[@]}"
	do
		if [ -e ~/${file} ]; then
			echo "backup ${file}"
			mv ~/${file} ${BK_DIR}
		else
			echo "no ${file} detected in ${HOME}"
		fi
	done

}

install_dotfiles() {

	cd ${SRC_DIR}
	for file in "${FILE_LIST[@]}"
	do
		if [ -f ${file} ]; then
			echo "install ${file}"
			ln -s ${SRC_DIR}/${file} ~/${file}
		else
			echo "no ${file} detected in ${SRC_DIR}"
		fi
	done

}

install_linux_package() {

	apt-get -v >/dev/null 2>&1 || { echo "no apt-get found. exit 1" >&2; exit 1; }
	sudo apt-get update
	sudo apt-get install git vim screen

	mkdir -p ~/.vim/bundle
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

}

install_for_linux() {

	#install_linux_package
	backup_dotfiles
	install_dotfiles
}


main() {

	 print_var

	 case ${OS} in
		"Linux")
		install_for_linux
 		;;
		*)
		echo "Do not support ${OS} now"
		;;
	esac


}


main
