# KVM

## [KVM Tutorial](https://www.server-world.info/en/note?os=Ubuntu_18.04&p=kvm&f=1)

```bash
#!/bin/bash

BASEPATH=$(realpath `dirname $0`)

sudo virt-install \
         -n ubuntu1804 \
         --os-type=Linux \
         --os-variant=ubuntu18.04 \
         --memory=131072 \
         --vcpus=18 \
         --disk path=${BASEPATH}/ubuntu1804.img,size=128  \
         --network network:default \
         --graphics none  \
         --console pty,target_type=serial \
         --extra-args 'console=ttyS0,115200n8 serial' \
         --location 'http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/' \
```

## [How to find ip address of Linux KVM guest virtual machine](https://www.cyberciti.biz/faq/find-ip-address-of-linux-kvm-guest-virtual-machine/)

## [How to clone existing KVM virtual machine images on Linux](https://www.cyberciti.biz/faq/how-to-clone-existing-kvm-virtual-machine-images-on-linux/)

## [Static IP addresses in a KVM network](https://tqdev.com/2020-kvm-network-static-ip-addresses)
#### [KVM libvirt assign static guest IP addresses using DHCP on the virtual machine](https://www.cyberciti.biz/faq/linux-kvm-libvirt-dnsmasq-dhcp-static-ip-address-configuration-for-guest-os/)

## [KVM Nested](https://opengers.github.io/virtualization/kvm-nested-virtualization/)

