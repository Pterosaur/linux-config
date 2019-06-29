FROM ubuntu:18.04

WORKDIR /root

RUN \
   sed -i 's/http:\/\/archive\.ubuntu\.com\/ubuntu\//http:\/\/mirrors\.aliyun\.com\/ubuntu\//g' /etc/apt/sources.list

# Init environment
RUN \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y curl sudo

# Install environment
RUN \
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/Pterosaur/linux-config/master/ubuntu-init.sh)"
