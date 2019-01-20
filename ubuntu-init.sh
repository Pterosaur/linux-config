#!/bin/bash

config_url="https://raw.githubusercontent.com/Pterosaur/linux-config/master/conf/"

execute() {
    # args
    # 1: command
    # 2: run as root > 0, else as current user
    local prefix=""
    if [[ $2 && $2 -gt 0 && ( $(whoami) != "root" ) ]]; then
        prefix="sudo"
    fi
    
    echo -e '\E[32;40m'"$prefix $1"
    tput sgr0
    sh -c "$prefix $1"
    if [ $? -ne 0 ];then
        exit 1
    fi
}

is_command_existed() {
    # args
    # 1: command name
    if command -v $1 > /dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

install_command() {
    # args
    # 1: command name
    # 2: package name
    if is_command_existed $1; then
        execute " apt install -y $2" 1
        if [ $? -ne 0 ];then
            exit 1
        fi
        return 1
    fi
    return 0
}

write_config() {
    # args
    # 1: config name
    # 2: content
    # 3: overrite > 0, else append
    local file=$1
    local content=$2
    local action=">>"
    if [ ! -e $file ]; then
        touch $file
    fi
    if [ ! -w $file ]; then
        exit 1
    fi

    if [[ $3 && $3 -gt 0 ]]; then
        action=">"
    fi
    
    execute "echo \"$content\" $action $file"
}

init_vim() {

    # install vim
    install_command "vim" "vim"

    # configure vimrc
    local vimrc="$(curl -fsSL ${config_url}vimrc)"
    local config_file="$HOME/.vimrc"
    write_config "$config_file" "$vimrc" 1

} 

init_git() {
    # install git
    install_command "git" "git"

    execute "git config --global core.editor \"vim\""
}

init_zsh() {
    # install git
    if install_command "zsh" "zsh"; then
        return
    fi
    install_command "curl" "curl"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    execute "sed -i -e \"s/^ZSH_THEME=.*$/ZSH_THEME=\\\"ys\\\"/\" $HOME/.zshrc"
    execute "sed -i -e \"s/^plugins=(/plugins=( extract z sudo /\" $HOME/.zshrc"
}

init_samba() {
    # include samba
    install_command "samba" "samba"
    install_command "smbclient" "smbclient"

    # configure samba 
    local config="/etc/samba/smb.conf"
    local passwd="000000"
    local smbconf="$(curl -fsSL ${config_url}smb.conf)"
    smbconf=$(sh -c "echo \"${smbconf}\"")

    local key="${smbconf//[[:blank:]]/}"
    key=(${key//\n/})
    local original_conf=$(sed -e "s/\(\\s\)//g" ${config})
    original_conf=(${original_conf//\n/})

    # insert config if no item
    if [[ "${original_conf[*]}" != *" ${key} "* ]]; then
        write_config "$config" "$smbconf"
        execute "echo \"$passwd\n$passwd\" | smbpasswd -a $user -s"
        execute "service smbd restart" 1
    fi


}

init_tmux() {
    # include tmux
    install_command "tmux" "tmux"
    
    # configure tmux
    local config="$HOME/.tmux.conf"
    local tmuxconf="$(curl -fsSL ${config_url}tmux.conf)"
    write_config "$config" "$tmuxconf" 1
}



main() {

    # vim git zsh samba tmux
    local install_modules=(vim git zsh samba tmux)

    if [ $# -gt 0 ]; then
        install_modules=($@)
    fi
    echo 'Install "'${install_modules[*]}'"'


    for module in ${install_modules[@]};
    do
        eval "init_"$module
    done
}

main ${@}


