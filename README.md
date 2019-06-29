# linux-config

Automatically Install
``` bash
# Install docker image
sh -c "$(curl -fsSL get.docker.com)
docker build -t zegan https://raw.githubusercontent.com/Pterosaur/linux-config/master/Dockerfile
```
``` bash
# ubuntu init
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Pterosaur/linux-config/master/ubuntu-init.sh)"
```

## Detail

## vim
```
sudo apt install vim

#set table to 4 spaces
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert 4 spaces
set expandtab

```

## git
```
#set git editor as vim
git config --global core.editor "vim"
```

## ssh 
```
# public-privite key authentication

vim /etc/ssh/sshd_config

AuthorizedKeysFile %h/.ssh/authorized_keys
#copy public key to .ssh/authorized_keys

```

## zsh (advanced bash)
```
#install zsh
sudo apt install zsh
sudo yum install zsh


#install oh-my-zsh
#https://github.com/robbyrussell/oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

#set theme

vim ~/.zshrc
ZSH_THEME="ys"

#set plugin

vim ~/.zshrc
plugins=(git extract z sudo)

#install auto-complete command plugin incr
#http://mimosa-pudica.net/zsh-incremental.html

mkdir -p ~/.oh-my-zsh/plugins/incr/

wget http://mimosa-pudica.net/src/incr-0.2.zsh

vim ~/.zshrc

source ~/.oh-my-zsh/plugins/incr/incr*.zsh

```

# samba (file shared with windows)
```
#install samba
sudo apt install samba
#config samba


vim /etc/samba/smb.conf
#share path's alias shown in client
[share]
#local path wanted to be shared
path=/
available=yes
valid users=user
read only=no
browsable=yes
public=yes
writable=yes

smbpasswd -a user

sudo service smbd restart
```

## tmux(multiple screen)
```
#vi mode in tmux
vim ~/.tmux.conf

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

```

