#!/bin/bash



execute() {
    # args
    # 1: command
    # 2: run as root > 0, else as current user
    prefix=""
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
    file=$1
    content=$2
    action=">>"
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
    vimrc="
set tabstop=4
set shiftwidth=4
set expandtab
set nu
    "
    config_file="$HOME/.vimrc"
    write_config "$config_file" "$vimrc"

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
    config="/etc/samba/smb.conf"
    user=$(whoami)
    passwd="000000"
    smbconf="
[share_$user]
path=$HOME
available=yes
valid user=$user
read only=no
browsable=yes
public=yes
writable=yes
    "
    write_config "$config" "$smbconf"
    execute "echo \"$passwd\n$passwd\" | smbpasswd -a $user -s"
    execute "service smbd restart" 1

}

init_tmux() {
    # include tmux
    install_command "tmux" "tmux"
    
    # configure tmux
    config="$HOME/.tmux.conf"
    tmuxconf="
    set-window-option -g mode-keys vi
    #mouse mode
    set -g mouse on

    set -g prefix C-z
    set -g base-index 1
    set -g mouse on
    set -g pane-base-index 1
    set -g renumber-windows on
    set-window-option -g mode-keys vi

    # hjkl pane traversal
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    # List of plugins
    set -g @plugin 'tmux-plugins/tpm'
    set -g @plugin 'tmux-plugins/tmux-sensible'

    # Other examples:
    # set -g @plugin 'github_username/plugin_name'
    # set -g @plugin 'git@github.com/user/plugin'
    # set -g @plugin 'git@bitbucket.com/user/plugin'

    set -g @plugin 'tmux-plugins/tmux-resurrect'
    set -g @plugin 'tmux-plugins/tmux-yank'

    # Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
    run '~/.tmux/plugins/tpm/tpm'
    "
    write_config "$config" "$tmuxconf"
}



main() {

    # vim git zsh samba tmux
    install_modules=(vim git zsh samba tmux)

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
