ARG UBUNTU_VERSION=20.04

FROM ubuntu:${UBUNTU_VERSION}

WORKDIR /root

ARG IN_CHINA=false

RUN \
   if ${IN_CHINA}; \
   then \
      sed -i 's/http:\/\/archive\.ubuntu\.com\/ubuntu\//http:\/\/mirrors\.aliyun\.com\/ubuntu\//g' /etc/apt/sources.list; \
   fi

# Install environment
ADD ubuntu-init.sh .ubuntu-init

RUN \
   bash .ubuntu-init; \
   bash .ubuntu-init dev; \
   rm .ubuntu-init

CMD \
   zsh
