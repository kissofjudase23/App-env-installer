#!/bin/bash
source ./system_info.sh

DOT_FILE_LIST=( ".bashrc"\
            ".vimrc"\
            ".gitconfig"\
            ".git-prompt.sh"\
            ".screenrc"\
            ".gdbinit"\
            ".bash_profile")

backup_dotfiles() {
    echo "========================="
    echo "Start to Backup dotfiles:"
    rm -rf ${BK_DIR}/*
    mkdir -p ${BK_DIR}/

    cd ${BK_DIR}
    for file in "${DOT_FILE_LIST[@]}"
    do
        if [ -e ~/${file} ]; then
            echo "backup ${file}"
            mv ~/${file} ${BK_DIR}
        else
            echo "no ${file} detected in ${HOME}"
        fi
    done
    echo "Backup has been done!"
    echo "========================="
}

install_dotfiles() {
    echo "========================="
    echo "Start to Install dotfiles:"
    cd ${SRC_DIR}
    for file in "${DOT_FILE_LIST[@]}"
    do
        if [ -f ${file} ]; then
            echo "install ${file}"
            ln -f -s ${SRC_DIR}/${file} ~/${file}
        else
            echo "no ${file} detected in ${SRC_DIR}"
        fi
    done
    echo "Installation has been done!"
    echo "========================="
}

backup_and_install() {
    backup_dotfiles
    install_dotfiles
}

install_bundle() {
    echo "install bundle"
    bundleDir=~/.vim/bundle/Vundle.vim/
    if [[ ! -d ${bundleDir} ]]; then
        mkdir -p ~/.vim/bundle
        git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    fi
}

install_ubuntu_package() {
    echo "install for Ubuntu:"
    apt-get -v >/dev/null 2>&1 || { echo "no apt-get found. exit 1" >&2; exit 1; }
    sudo apt-get update
    for package in "${install_list[@]}"
    do
        ${package} --version > /dev/null 2>&1 || {\
            echo "install ${package}";\
            sudo apt-get install ${package}
        }
    done
}

install_centos_package() {
    echo "install for CentOS"
    sudo yum update
    for package in "${install_list[@]}"
    do
        ${package} --version > /dev/null 2>&1 || {\
            echo "install ${package}";\
            sudo yum install ${package}
        }
    done
}

install_linux_package() {
    install_list=( "git"\
            "screen"\
            "ctags"\
            "cscope"\
            "realpath"\
    )
    dist=$(grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}')
    if [ "$dist" == "Ubuntu" ]; then
        install_ubuntu_package
    else
        install_centos_package
    fi
    install_bundle
}

install_darwin_package() {
    echo "install for Darwin"

    #install homebrew
    brew -v > /dev/null 2>&1 || {\
        echo "install homebrew";\
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";\
    }

    # install realpath
    realpath . > /dev/null 2>&1 || {\
        echo "install realpath";\
        brew tap iveney/mocha;\
        brew install realpath;\
    }
    #install git
    git --version > /dev/null 2>&1 || {\
        echo "install git";\
        brew install git;\
    }
    #install bundle
    install_bundle
}

install_for_Linux() {
    install_linux_package
    backup_and_install
}

install_for_darwin() {
    install_darwin_package
    backup_and_install
}

main() {
     case ${OS} in
        "Linux")
        install_for_Linux
        ;;
        "Darwin")
        install_for_darwin
        ;;
        *)
        echo "Do not support ${OS} now"
        ;;
    esac
}

main
