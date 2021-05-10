ARG UBUNTU_VERSION=20.04

FROM ubuntu:${UBUNTU_VERSION}

RUN apt-get update
RUN apt-get install -y sudo
RUN useradd -ms /bin/bash -G sudo zegan
RUN usermod -aG root zegan
RUN usermod -aG sudo zegan
RUN echo "zegan ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER zegan
ENV USER=zegan
WORKDIR /home/zegan

ARG IN_CHINA=false

RUN \
   if ${IN_CHINA}; \
   then \
      sed -i 's/http:\/\/archive\.ubuntu\.com\/ubuntu\//http:\/\/mirrors\.aliyun\.com\/ubuntu\//g' /etc/apt/sources.list; \
   fi

# Install environment
ADD ubuntu-init.sh /usr/bin/ubuntu-init

RUN \
   bash ubuntu-init; \
   bash ubuntu-init dev;

CMD \
   zsh
