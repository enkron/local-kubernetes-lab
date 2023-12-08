#!/bin/bash

set -u -o pipefail


BASE_IMAGE_LOC="http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
BASE_IMAGE_TAG=$(echo $BASE_IMAGE_LOC |cut -d/ -f6)

test "${#}" -eq 0 && { echo no vm name supplied; exit 1; }
test -s $BASE_IMAGE_TAG || curl -fL# -o $BASE_IMAGE_TAG $BASE_IMAGE_LOC

for img in "${@}"; do
    qemu-img create -b $BASE_IMAGE_TAG -f qcow2 -F qcow2 "${img}.img" 10G
    echo -e "instance-id: ${img}\nlocal-hostname: ${img}" > meta-data
    genisoimage -output cidata.iso -V cidata -r -J user-data meta-data
    virt-install \
        --name="${img}" \
        --ram=2048 \
        --vcpus=2 \
        --import \
        --disk path="${img}.img",format=qcow2 \
        --disk path=cidata.iso,device=cdrom \
        --os-variant=ubuntu20.04 \
        --network bridge=virbr0,model=virtio \
        --graphics vnc,listen=0.0.0.0 \
        --noautoconsole
done
