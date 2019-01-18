#!/bin/bash

#

# vim git zsh 
enable_modules=()

if [ $# -gt 0 ]; then
    enable_modules=${@}
fi
echo ${enable_modules[*]}

function execute() {
    echo -e '\E[32;40m'"$1"
    tput sgr0
    sh -c "$1"
    if [ $? -ne 0 ];then
        exit 1
    fi
}

function is_command_existed() {
    if command -v $1 > /dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

function install_command() {
    if is_command_existed $1; then
        execute "apt install -y $2"
        if [ $? -ne 0 ];then
            exit 1
        fi
        return 1
    fi
    return 0
}

function write_config() {
    file=$1
    content=$2
    if [ ! -e $file ]; then
        touch $file
    fi
    if [ ! -w $file ]; then
        exit 1
    fi
    execute "echo \"$content\" >> $file"
}

function init_vim() {
    # install vim
    install_command "vim" "vim"

    # configure vimrc
    vimrc_content="
set tabstop=4
set shiftwidth=4
set expandtab
set nu
    "
    config_file="$HOME/.vimrc"
    write_config "$config_file" "$vimrc_content"

} 

function init_git() {
    # install git
    install_command "git" "git"

    execute "git config --global core.editor \"vim\""
}

function init_zsh() {
    # install git
    if install_command "zsh" "zsh"; then
        return
    fi
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    execute "sed -i -e \"s/^ZSH_THEME=.*$/ZSH_THEME=\\\"ys\\\"/\" $HOME/.zshrc"
    execute "sed -i -e \"s/^plugins=(/plugins=( extract z sudo /\" $HOME/.zshrc"
}


for module in ${enable_modules[@]};
do
    eval "init_"$module
done

