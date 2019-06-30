FROM ubuntu:18.04

WORKDIR /root

RUN \
   sed -i 's/http:\/\/archive\.ubuntu\.com\/ubuntu\//http:\/\/mirrors\.aliyun\.com\/ubuntu\//g' /etc/apt/sources.list

# Init environment
RUN \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y wget curl sudo

# Install environment
RUN \
   wget https://raw.githubusercontent.com/Pterosaur/linux-config/master/ubuntu-init.sh -O .init.sh
RUN \
   bash .init.sh

CMD \
   zsh
