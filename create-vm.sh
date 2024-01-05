#!/bin/bash

set -u -o pipefail

unset -v VM_TAG

BASE_IMAGE_LOC="http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
BASE_IMAGE_TAG=$(echo $BASE_IMAGE_LOC |cut -d/ -f6)
USER_DATA=

usage() {
    echo 'usage: create-vm.sh -d USER_DATA VM_TAG' && exit 0
}

while getopts "d:" flags; do
    case "${flags}" in
        d)
            USER_DATA="${OPTARG}"
            cp "${USER_DATA}" user-data || exit 1
            ;;

        *) usage ;;
    esac
done

VM_TAG="${@:$OPTIND:1}"

if [ -z "${USER_DATA}" ] && [ -z "${VM_TAG}" ]; then
    usage
fi
: "${USER_DATA:?no user-data supplied}" "${VM_TAG:?vm is not supplied}"
test -s "${BASE_IMAGE_TAG}" || curl -fL# -o "${BASE_IMAGE_TAG}" "${BASE_IMAGE_LOC}"

qemu-img create -b $BASE_IMAGE_TAG -f qcow2 -F qcow2 "${VM_TAG}.img" 10G
echo -e "instance-id: ${VM_TAG}\nlocal-hostname: ${VM_TAG}" > meta-data
genisoimage -output "${VM_TAG}-cidata.iso" -V cidata -r -J user-data meta-data
virt-install \
    --name="${VM_TAG}" \
    --ram=2048 \
    --vcpus=2 \
    --import \
    --disk path="${VM_TAG}.img",format=qcow2 \
    --disk path="${VM_TAG}-cidata.iso",device=cdrom \
    --os-variant=ubuntu20.04 \
    --network bridge=virbr0,model=virtio \
    --graphics vnc,listen=0.0.0.0 \
    --noautoconsole

rm ./user-data
