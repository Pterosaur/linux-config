#!/bin/bash

config_url="https://raw.githubusercontent.com/Pterosaur/linux-config/master/conf/"

execute() {
    # args
    # 1: command
    
    echo -e '\E[32;40m'" $1"
    tput sgr0
    sh -c " $1"
    if [ $? -ne 0 ];then
        exit 1
    fi
}

is_command_existed() {
    # args
    # 1: command name
    if command -v $1 > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

install_command() {
    # args
    # 1: command name
    # 2: package name
    if ! is_command_existed "apt-fast"; then
        execute "sudo apt-get update"
        execute "printf \"6\n70\n\" | sudo apt-get install -y expect"
        execute "sudo apt-get install -y software-properties-common"
        execute "sudo add-apt-repository -y ppa:apt-fast/stable"
        execute "sudo apt-get update"
        execute "printf \"1\n$(grep -c ^processor /proc/cpuinfo)\nyes\n\" | sudo apt-get -y install apt-fast "
    fi
    if ! is_command_existed $1; then
        execute "sudo apt-fast install -y $2"
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
    #if install_command "zsh" "zsh"; then
    #    return
    #fi
    execute 'print "exit\n" | sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"'
    execute "sed -i -E \"s/^ZSH_THEME=.*$/ZSH_THEME=\\\"ys\\\"/\" $HOME/.zshrc"
    execute "sed -i -E \"s/^plugins=\(/plugins=\( extract z sudo /\" $HOME/.zshrc"
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
    local original_conf=$(sed -E "s/\(\\s\)//g" ${config})
    original_conf=(${original_conf//\n/})

    # insert config if no item
    if [[ "${original_conf[*]}" != *" ${key} "* ]]; then
        write_config "$config" "$smbconf"
        execute "echo \"$passwd\n$passwd\" | sudo smbpasswd -a $user -s"
        execute "sudo service smbd restart"
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

init_ripgrep() {

    if ! is_command_existed "rg"; then
        execute "curl -LO https://github.com/BurntSushi/ripgrep/releases/download/0.10.0/ripgrep_0.10.0_amd64.deb"
        execute "sudo dpkg -i ripgrep_0.10.0_amd64.deb"
        execute "rm ripgrep_0.10.0_amd64.deb"
    fi

}

init_dev() {

    execute "sudo sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list"
    execute "sudo apt-fast update"

    install_command "gcc" "build-essential"

    execute "sudo apt-fast build-dep -y vim"

}

main() {

    # vim git zsh samba tmux ripgrep dev
    local install_modules=(vim git zsh samba tmux ripgrep dev)

    if [ $# -gt 0 ]; then
        install_modules=($@)
    fi
    echo 'Install "'${install_modules[*]}'"'

    install_command "curl" "curl"

    for module in ${install_modules[@]};
    do
        eval "init_"$module
    done
}

main ${@}


