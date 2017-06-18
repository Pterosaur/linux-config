#!/bin/bash

#softmanager
grep -iq centos /etc/issue
install='apt install'
if [ $? = 0 ] 
then
    install='yum install'
#elif [$?  0]
#then
#    echo "/etc/issue isn't existent\n"
#    exit $1
fi

echo $install
##install htop
#$install htop
#
##install zsh
#$install zsh

