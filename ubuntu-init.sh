#!/bin/bash

set -x -e -u
set -o pipefail

# Test on Ubuntu 18.04

config_url="https://raw.githubusercontent.com/Pterosaur/linux-config/master/conf/"
init_conf_flag="Zegan conf init"

execute() {
    # args
    # 1: command
    # 2: run as root > 0, else as current user
    local prefix=""
    if [[ $# -gt 1 && $2 -gt 0 ]]; then
        prefix="sudo"
    fi    

    if [[ $- == *i* ]];then
        tput sgr0
    fi

    ${prefix} bash -c " $1"
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
    if ! is_command ${1}; then
        execute "apt-fast install -y ${@:2}" 1
    fi
}

write_config() {
    # args
    # 1: config name
    # 2: content
    # 3: overrite == 1 overwirte, else append
    local file=$1
    local content=$2
    local action=">>"
    if [ ! -e $file ]; then
        touch $file
    fi

    if [[ $# -gt 2 && $3 -eq 1 ]]; then
        action=">"
    fi
    local need_sudo=0
    if [[ $# -gt 3 && $4 -eq 1 ]]; then
        need_sudo=1
    fi
    
    execute "printf \"${content}\n\" ${action} ${file}" "${need_sudo}"
    execute "printf \"\n\" >> ${file}" "${need_sudo}"
}

init_vim() {

    # install vim
    install_command "vim" "vim"

    # configure vimrc
    local vimrc="${HOME}/.vimrc"
    local content="$(curl -fsSL ${config_url}vimrc)"

    if [[ -e ${vimrc} && $(cat ${vimrc}) == *"${init_conf_flag}"* ]]; then
        return
    fi
    write_config "${vimrc}" "\\\" ${init_conf_flag}"
    write_config "${vimrc}" "${content}"
} 

init_git() {
    # install git
    install_command "git" "git"

    execute "git config --global core.editor \"vim\""
}

init_zsh() {
    # install git
    install_command "zsh" "zsh"

    if [[ ! -e ".oh-my-zsh" ]]; then
        execute 'print "exit\n" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"'
    fi
    execute "chsh -s `which zsh`"

    zshrc="${HOME}/.zshrc"
    if [[ -e ${zshrc} && $(cat ${zshrc}) == *"${init_conf_flag}"* ]]; then
        return
    fi
    write_config "${zshrc}" "# ${init_conf_flag}"
    execute "sed -i -E \"s/^ZSH_THEME=.*$/ZSH_THEME=\\\"ys\\\"/\" ${zshrc}"
    execute "sed -i -E \"s/^plugins=\(/plugins=\( extract z sudo /\" ${zshrc}"
    write_config "${zshrc}" "setopt nosharehistory"
}

init_samba() {
    # include samba
    install_command "samba" "samba"
    install_command "smbclient" "smbclient"

    # configure samba 
    local smbconf="/etc/samba/smb.conf"
    local user=$(whoami)
    local passwd="000000"
    local content="$(curl -fsSL ${config_url}smb.conf)"

    if [[ $(cat ${smbconf}) == *"${init_conf_flag}"* ]]; then
        return
    fi
    write_config "${smbconf}" "# ${init_conf_flag}"
    write_config "${smbconf}" "${content}" 0 1
    execute "printf \"${passwd}\n${passwd}\" | sudo smbpasswd -a ${user} -s"
    execute "service smbd restart" 1

}

init_tmux() {
    # include tmux
    install_command "tmux" "tmux"
    
    # configure tmux
    local tmuxconf="$HOME/.tmux.conf"
    local content="$(curl -fsSL ${config_url}tmux.conf)"
    
    if [[ $(cat ${tmuxconf}) == *"${init_conf_flag}"* ]]; then
        return
    fi
    write_config "${tmuxconf}" "# ${init_conf_flag}"
    write_config "${tmuxconf}" "${content}"
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

    install_command "wget" "wget"

    install_command "ip" "net-tools" 
}

init_docker() {
    #install docker
    if ! is_command "docker"; then
        execute 'sh -c "$(curl -fsSL get.docker.com)"'
    fi
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
        "gdb"
        "vim-scripts"
        "vim-doc"
        "ctags"
    )
    execute "apt-fast install -y ${dev_packages[*]}" 1
    
    #install ConqueGDB
    if [[ $(find ${HOME}/.vim -name 'conque_gdb.vim' | wc -l) -eq 0 ]]; then
        execute "wget ${config_url}conque_gdb.vmb"
        execute "vim conque_gdb.vmb -c \"so %\" -c \"q\""
        execute "rm conque_gdb.vmb"
    fi

    #install vim plugin
    if ! is_command "vim-addon-manager"; then
        local vimrc="${HOME}/.vimrc"

        execute "apt-fast install -y vim-addon-manager"

        # YouCompleteMe
        execute "apt-fast install -y vim-youcompleteme"
        execute "vim-addon-manager install youcompleteme"
        local ycm="$(curl -fsSL ${config_url}vimrc.youcompleteme)"
        write_config "${vimrc}" "${ycm}" 

        # tag list
        execute "vim-addon-manager install taglist"

        # pathogen
        execute "mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim"
        write_config "${vimrc}" "execute pathogen#infect()" 

        # NerdTree
        execute "git clone https://github.com/scrooloose/nerdtree.git ~/.vim/bundle/nerdtree"
        local nt="$(curl -fsSL ${config_url}vimrc.nerdtree)"
        write_config "${vimrc}" "${nt}"

        # WinManager
        execute "vim-addon-manager install winmanager"
        local wm_vim="${HOME}/.vim/plugin/winmanager.vim"
        local wm="$(curl -fsSL ${config_url}winmanager.vim)"
        write_config "${wm_vim}" "${wm}"
        local wm="$(curl -fsSL ${config_url}vimrc.winmanager)"
        write_config "${vimrc}" "${wm}"
        
    fi
}

init_man() {
    man_packets=(
        "man"
        "manpages" 
        "manpages-dev" 
        "freebsd-manpages"
        "man2html"
        "manpages-posix"
        "manpages-posix-dev"
    )

    execute " apt-fast install -y " 1
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
    local install_modules=(vim git zsh tmux tools man)

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


