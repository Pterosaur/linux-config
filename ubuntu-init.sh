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
    if [[ $# -gt 1 && $2 -gt 0 ]]
    then
        # If the user is root
        if [[ $EUID -ne 0 ]]
        then
            prefix="sudo"
        fi
    fi    

    if [[ $- == *i* ]]
    then
        tput sgr0
    fi

    ${prefix} bash -c " $1"
}

is_command() {
    # args
    # 1: command name
    if command -v $1 > /dev/null 2>&1
    then
        echo 1
    else
        echo 0
    fi
}

installed_pkgs=$(apt-get -qq list 2>/dev/null | perl -n -e '/([^\/]+)\/.*\[installed\]/ && print " $1 "')

is_installed() {
    # args
    # 1: pakcage name
    if [[ ${installed_pkgs} =~ (^|[[:space:]])${1}($|[[:space:]]) ]]
    then
        echo 1
    else
        installed_pkgs=$(apt-get -qq list 2>/dev/null | perl -n -e '/([^\/]+)\/.*\[installed\]/ && print " $1 "')
        if [[ ${installed_pkgs} =~ (^|[[:space:]])${1}($|[[:space:]]) ]]
        then
            echo 1
        else
            echo 0
        fi
    fi
}

install_modules() {
    # args
    # 1: package name
    if [[ $(is_command "apt-fast") == 0 ]]
    then
        execute "apt-get update" 1
        execute "printf \"6\n70\n\" | apt-get install -y expect" 1
        execute "apt-get install -y software-properties-common" 1
        execute "add-apt-repository main" 1
        execute "add-apt-repository universe" 1
        execute "add-apt-repository restricted" 1
        execute "add-apt-repository multiverse" 1
        execute "add-apt-repository -y ppa:apt-fast/stable" 1
        execute "apt-get update" 1
        execute "printf \"1\n$(grep -c ^processor /proc/cpuinfo)\nyes\n\" | apt-get -y install apt-fast " 1
    fi
    if [[ $(is_installed ${1}) == 0 ]]
    then
        execute "apt-fast install -y ${@}" 1
    fi
}

write_config() {
    # args
    # 1: config name
    # 2: content
    # 3: action == 1 overwirte, else append
    # 4: need_sudo == 1 sudo, else no

    local file=$1
    local content=$( base64 <<< "${2}" )
    local action=">>"
    if [ ! -e $file ]
    then
        touch $file
    fi

    if [[ $# -gt 2 && $3 -eq 1 ]]
    then
        action=">"
    fi
    local need_sudo=0
    if [[ $# -gt 3 && $4 -eq 1 ]]
    then
        need_sudo=1
    fi

    execute "printf \"${content}\n\" | base64 -d ${action} ${file}" "${need_sudo}"
    execute "printf \"\n\" >> ${file}" "${need_sudo}"
}

init_vim() {

    # install vim
    install_modules "vim"

    # configure vimrc
    local vimrc="${HOME}/.vimrc"
    local content="$(curl -fsSL ${config_url}vimrc)"

    if [[ -e ${vimrc} && $(cat ${vimrc}) == *"${init_conf_flag}"* ]]
    then
        return
    fi
    write_config "${vimrc}" "\" ${init_conf_flag}"
    write_config "${vimrc}" "${content}"

    if [[ $( find ${vimdir} -name 'pathogen*' | wc -l ) -eq 0 ]]
    then
        # pathogen
        execute "mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim"
        write_config "${vimrc}" "execute pathogen#infect()" 
    fi

    # Change theme
    execute "git clone https://github.com/morhetz/gruvbox.git ~/.vim/bundle/gruvbox"
    write_config  "${vimrc}" "set t_Co=256"
    write_config  "${vimrc}" "colorscheme gruvbox"
    write_config  "${vimrc}" "set background=dark"

    write_config "${vimrc}" "\" ${init_conf_flag}"
} 

init_git() {
    # install git
    install_modules "git"

    execute "git config --global core.editor \"vim\""
}

init_zsh() {
    # install git
    install_modules "zsh"

    if [[ ! -e "${HOME}/.oh-my-zsh" ]]
    then
        execute 'print "exit\n" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"'
    fi
    execute "chsh -s `which zsh` `whoami`" 1

    local zshrc="${HOME}/.zshrc"
    if [[ -e ${zshrc} && $(cat ${zshrc}) == *"${init_conf_flag}"* ]]
    then
        return
    fi
    write_config "${zshrc}" "# ${init_conf_flag}"
    execute "sed -i -E \"s/^ZSH_THEME=.*$/ZSH_THEME=\\\"ys\\\"/\" ${zshrc}"
    execute "sed -i -E \"s/^plugins=\(/plugins=\( extract z sudo fzf-tab zsh-completions /\" ${zshrc}"
    local content=$(curl -fsSL ${config_url}zshrc)
    write_config "${zshrc}" "${content}"

    git clone https://github.com/Aloxaf/fzf-tab ${HOME}/.oh-my-zsh/custom/plugins/fzf-tab
    git clone https://github.com/zsh-users/zsh-completions.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-completions
}

init_samba() {
    # include samba
    install_modules "samba"
    install_modules "smbclient"

    # configure samba 
    local smbconf="/etc/samba/smb.conf"
    local user=$(whoami)
    local passwd="000000"
    local content="$(curl -fsSL ${config_url}smb.conf)"

    if [[ $(cat ${smbconf}) == *"${init_conf_flag}"* ]]
    then
        return
    fi
    write_config "${smbconf}" "# ${init_conf_flag}" 0 1
    write_config "${smbconf}" "${content}" 0 1
    execute "printf \"${passwd}\n${passwd}\" | sudo smbpasswd -a ${user} -s"
    execute "service smbd restart" 1

}

init_tmux() {
    # include tmux
    install_modules "tmux"
    
    # configure tmux
    local tmuxconf="$HOME/.tmux.conf"
    local content="$(curl -fsSL ${config_url}tmux.conf)"
    
    if [[ $(cat ${tmuxconf}) != *"${init_conf_flag}"* ]]
    then
        write_config "${tmuxconf}" "# ${init_conf_flag}"
        write_config "${tmuxconf}" "${content}"
        write_config "${tmuxconf}" "# ${init_conf_flag}"
    fi
    
    local bash_aliases="$HOME/.bash_aliases"
    if [[ $(cat ${bash_aliases}) != *tmux* ]]
    then
        write_config "${bash_aliases}" "alias tmux='tmux -2'"
        write_config "${bash_aliases}" "alias tn='tmux -2 new-session -s'"
        write_config "${bash_aliases}" "alias tnw='tmux -2 new-window'"
        write_config "${bash_aliases}" "alias tl='tmux -2 list-session'"
        write_config "${bash_aliases}" "alias ta='tmux -2 attach -t'"
    fi
}

init_tools() {
    tools_packages=(
        "htop" 
        "tree" 
        "telnet"
        "net-tools"
        "iputils-ping"
        "iproute2"
        "iproute2-doc"
        "fzf"
    )
    execute "apt-fast install -y ${tools_packages[*]}" 1

    init_man

    init_docker

    if [[ $(is_command "rg") == 0 ]]
    then
        execute "wget https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep_12.1.1_amd64.deb -O /tmp/ripgrep.deb"
        execute "dpkg -i /tmp/ripgrep.deb" 1
    fi
}

init_docker() {
    #install docker
    if [[ $(is_command "docker") == 0 ]]
    then
        execute 'sh -c "$(curl -fsSL get.docker.com)"' 1
    fi
    if [[ $(id -u) != 0 ]]
    then
        execute "usermod -aG docker $(whoami)" 1
    fi
}

init_dev() {
    
    # install develop tools
    dev_packages=(
        "build-essential" 
        "python-dev" 
        "python3-dev"
        "python3-pip"
        "cmake"
        "libtool"
        "m4"
        "automake"
        "gdb"
        "vim-scripts"
        "vim-doc"
    )
    execute "apt-fast install -y ${dev_packages[*]}" 1

    #install vim plugin
    local vimdir="${HOME}/.vim"
    local vimrc="${HOME}/.vimrc"
    install_modules "vim-addon-manager"

    if [[ $( find ${vimdir} -name 'pathogen.vim' | wc -l ) -eq 0 ]]
    then
        # pathogen
        execute "mkdir -p ${vimdir}autoload ${vimdir}/bundle && curl -LSso ${vimdir}/autoload/pathogen.vim https://tpo.pe/pathogen.vim"
        write_config "${vimrc}" "execute pathogen#infect()" 
    fi

    #install ConqueGDB
    if [[ $(find ${vimdir} -name 'conque_gdb.vim' | wc -l) -eq 0 ]]
    then
        execute "git clone https://github.com/vim-scripts/Conque-GDB.git ${vimdir}/bundle/Conque-GDB"
        local conquegdb="$(curl -fsSL ${config_url}vimrc.conquegdb)"
        write_config "${vimrc}" "${conquegdb}"
    fi

    if [[ $( find ${vimdir} -name 'youcompleteme*' | wc -l ) -eq 0 ]]
    then
        # YouCompleteMe
        execute "apt-fast install -y vim-youcompleteme" 1
        execute "vim-addon-manager install youcompleteme"
        local ycm="$(curl -fsSL ${config_url}vimrc.youcompleteme)"
        write_config "${vimrc}" "${ycm}" 
    fi

    if [[ $( find ${vimdir} -name 'nerdtree*' | wc -l ) -eq 0 ]]
    then
        # NerdTree
        execute "git clone https://github.com/scrooloose/nerdtree.git ${vimdir}/bundle/nerdtree"
        local nt="$(curl -fsSL ${config_url}vimrc.nerdtree)"
        write_config "${vimrc}" "${nt}"
    fi

    if [[ $( find ${vimdir} -name 'taglist*' | wc -l ) -eq 0 ]]
    then
        # tag list
        execute "apt-fast install -y ctags" 1
        execute "vim-addon-manager install taglist"
    fi

    if [[ $( find ${vimdir} -name 'winmanager.vim' | wc -l ) -eq 0 ]]
    then
        # WinManager
        execute "vim-addon-manager install winmanager"
        local wm_vim="${vimdir}/plugin/winmanager.vim"
        local wm="$(curl -fsSL ${config_url}winmanager.vim)"
        write_config "${wm_vim}" "${wm}" 0 1
        local wm="$(curl -fsSL ${config_url}vimrc.winmanager)"
        write_config "${vimrc}" "${wm}"
    fi

    if [[ $( find ${vimdir} -name 'minibufexpl.vim' | wc -l ) -eq 0 ]]
    then
        execute "wget https://raw.githubusercontent.com/fholgado/minibufexpl.vim/master/plugin/minibufexpl.vim -O ${vimdir}/plugin/minibufexpl.vim "
        local minibufexpl="$(curl -fsSL ${config_url}vimrc.minibufexpl)"
        write_config "${vimrc}" "${minibufexpl}"
    fi

    if [[ $( find ${vimdir} -name 'ycm-generator.vim' | wc -l ) -eq 0 ]]
    then
        execute "apt-fast install -y clang" 1
        execute "git clone https://github.com/rdnetto/YCM-Generator.git ${vimdir}/bundle/YCM-Generator"
    fi

    if [[ $( find ${vimdir} -name 'color_coded.vim' | wc -l ) -eq 0 ]]
    then
        if ! [[ $(vim --version) =~ (lua5.([0-9]+)) ]]
        then
            echo "Miss vim that support Lua"
            exit 1
        fi
        execute "apt-fast install -y build-essential libtinfo5 libclang-dev libncurses-dev libz-dev cmake xz-utils libpthread-workqueue-dev lib${BASH_REMATCH[1]}-dev ${BASH_REMATCH[1]} " 1
        execute "git clone https://github.com/jeaye/color_coded.git ${vimdir}/bundle/color_coded"
        execute "cd ${vimdir}/bundle/color_coded && mkdir -p build && cd build && cmake .. && make -j && sudo make install && make clean && make clean_clang"
    fi
}

init_man() {

    execute "yes | unminimize || true" 1

    man_packets=(
        "man"
        "man-db"
        "manpages" 
        "manpages-dev" 
        "freebsd-manpages"
        "man2html"
        "manpages-posix"
        "manpages-posix-dev"
    )

    execute " apt-fast install -y ${man_packets[*]} " 1
}

init_kvm() {
    execute "apt-get install qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker" 1
}

init_kde() {
    install_modules "expect"
    execute "cat <<EOF | expect
set timeout -1
spawn apt-get install -y kubuntu-desktop
expect \"Default display manager: \"
send \"sddm\n\"
expect eof
EOF" 1
}

init_xrdp() {
    execute "apt-get install -y xrdp" 1
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
    local init_modules=("git" "zsh" "tmux" "vim" "tools")

    if [ $# -gt 0 ]
    then
        init_modules=($@)
    fi
    echo 'Install "'${init_modules[*]}'"'

    install_modules "sudo"
    install_modules "curl"
    install_modules "wget"

    for module in ${init_modules[@]};
    do
        eval "init_"$module
    done
}

main ${@}
