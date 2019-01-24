#!/bin/bash

# Test on Ubuntu 18.04

config_url="https://raw.githubusercontent.com/Pterosaur/linux-config/master/conf/"

execute() {
    # args
    # 1: command
    # 2: run as root > 0, else as current user
    local prefix=""
    if [[ $2 && $2 -gt 0 ]]; then
        prefix="sudo"
    fi    

    echo -e '\E[32;40m'" ${prefix} bash -c \"$1\""
    tput sgr0
    ${prefix} bash -c " $1"
    if [ $? -ne 0 ];then
        exit 1
    fi
}

is_command() {
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
    if ! is_command "apt-fast"; then
        execute "apt-get update" 1
        execute "printf \"6\n70\n\" | sudo apt-get install -y expect"
        execute "apt-get install -y software-properties-common" 1
        execute "add-apt-repository main" 1
        execute "add-apt-repository universe" 1
        execute "add-apt-repository restricted" 1
        execute "add-apt-repository multiverse" 1
        execute "add-apt-repository -y ppa:apt-fast/stable" 1
        execute "apt-get update" 1
        execute "printf \"1\n$(grep -c ^processor /proc/cpuinfo)\nyes\n\" | sudo apt-get -y install apt-fast "
    fi
    if ! is_command $1; then
        execute "apt-fast install -y $2" 1
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

    if [[ $3 && $3 -gt 0 ]]; then
        action=">"
    fi
    
    execute "echo \"$content\" $action $file" 1
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
    zshrc="$HOME/.zshrc"
    execute 'print "exit\n" | sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"'
    execute "sed -i -E \"s/^ZSH_THEME=.*$/ZSH_THEME=\\\"ys\\\"/\" $zshrc"
    execute "sed -i -E \"s/^plugins=\(/plugins=\( extract z sudo /\" $zshrc"
    write_config "$zshrc" "setopt nosharehistory"
}

init_samba() {
    # include samba
    install_command "samba" "samba"
    install_command "smbclient" "smbclient"

    # configure samba 
    local config="/etc/samba/smb.conf"
    local user=$(whoami)
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

init_tools() {

    if ! is_command "rg"; then
        execute "curl -LO https://github.com/BurntSushi/ripgrep/releases/download/0.10.0/ripgrep_0.10.0_amd64.deb"
        execute "dpkg -i ripgrep_0.10.0_amd64.deb" 1
        execute "rm ripgrep_0.10.0_amd64.deb"
    fi

    install_command "htop" "htop"

    install_command "tree" "tree"

    install_command "telnet" "telnet"

}

init_dev() {

    #execute "sudo sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list"
    #execute "sudo apt-fast update"

    #local root="$HOME/root"
    #local src="$root/src"
    #local bin="$bin/bin"
    #execute "mkdir -p ${root}"
    #execute "mkdir -p ${src}"
    #execute "mkdir -p ${bin}"
    
    # install develop tools
    dev_packages=(
        "build-essential" 
        "python-dev" 
        "python3-dev"
        "cmake"
        "libtool"
        "m4"
        "automake"
    )
    execute "apt-fast install -y ${dev_packages[*]}" 1

    # install vim YouCompleteMe
    execute "git clone https://github.com/Valloric/YouCompleteMe.git"
    execute "cd YouCompleteMe && git submodule update --init --recursive"
    execute "cd YouCompleteMe && python3 install.py --clang-completer"
    # execute "rm -rf YouCompleteMe"
    
    #install docker
    if ! is_command "docker"; then
        execute 'curl -fsSL get.docker.com -o get-docker.sh'
        execute 'sudo sh get-docker.sh'
        execute 'rm get-docker.sh'
    fi

}

init_kde() {
    install_command "expect"
    execute "cat <<EOF | expect
set timeout -1
spawn apt install -y kubuntu-desktop
expect \"Default display manager: \"
send \"sddm\n\"
expect eof
EOF" 1
    execute "reboot" 1
}

init_xrdp() {
    execute "apt install -y xrdp" 1
    execute "sed -e 's/^new_cursors=true/new_cursors=false/g' \
           -i /etc/xrdp/xrdp.ini" 1
    execute "systemctl enable xrdp" 1
    execute "systemctl restart xrdp" 1
    
    execute "echo \"startkde\" > ~/.xsession"
    execute "cat <<EOF > ~/.xsessionrc
export XDG_SESSION_DESKTOP=KDE
export XDG_DATA_DIRS=/usr/share/plasma:/usr/local/share:/usr/share:/var/lib/snapd/desktop
export XDG_CONFIG_DIRS=/etc/xdg/xdg-plasma:/etc/xdg:/usr/share/kubuntu-default-settings/kf5-settings
EOF"
    execute "cat <<EOF | \
  sudo tee /etc/polkit-1/localauthority/50-local.d/xrdp-NetworkManager.pkla
[Netowrkmanager]
Identity=unix-group:sudo
Action=org.freedesktop.NetworkManager.network-control
ResultAny=yes
ResultInactive=yes
ResultActive=yes
EOF"
    execute "cat <<EOF | \
  sudo tee /etc/polkit-1/localauthority/50-local.d/xrdp-packagekit.pkla
[Netowrkmanager]
Identity=unix-group:sudo
Action=org.freedesktop.packagekit.system-sources-refresh
ResultAny=yes
ResultInactive=auth_admin
ResultActive=yes
EOF"
    execute "systemctl restart polkit" 1
}

main() {

    # automatical : vim git zsh samba tmux tools
    # manuual : dev kde xrdp
    local install_modules=(vim git zsh samba tmux tools)

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


