FROM ubuntu:18.04

WORKDIR /root

# Init environment
RUN \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y curl sudo

# Install environment
RUN \
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/Pterosaur/linux-config/master/ubuntu-init.sh)"
RUN \
    rm init.sh