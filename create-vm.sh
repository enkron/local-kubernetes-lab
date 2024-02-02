#!/bin/bash
#
# The script downloads qcow2 nocloud image and builds kvm based instance
# on top of it.
#
# Base image locations:
# Ubuntu 20.04: http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
# Debian 10: https://cloud.debian.org/images/cloud/buster/latest/debian-10-nocloud-amd64.qcow2
# (currently debian is not working with the script properly)

set -u -o pipefail

unset -v VM_TAG

BASE_IMAGE_LOC="http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
BASE_IMAGE_TAG=$(echo $BASE_IMAGE_LOC |rev |cut -d/ -f1| rev)
USER_DATA=
SSH_PUBKEY=

usage() {
    echo 'usage: create-vm.sh -d USER_DATA -k SSH_PUBKEY VM_TAG' && exit 0
}

while getopts "d:k:" flags; do
    case "${flags}" in
        d)
            USER_DATA="${OPTARG}"
            cp "${USER_DATA}" user-data || exit 1
            ;;
        k)
            test -s "${OPTARG}" && SSH_PUBKEY="$(cat $OPTARG)" || { echo $OPTARG not a file; exit 1; }
            ;;
        *)
            usage
            ;;
    esac
done

VM_TAG="${@:$OPTIND:1}"

sed -i "s#\$SSH_PUBKEY#${SSH_PUBKEY}#g" ./user-data
sed -i "s#\$HOSTNAME#${VM_TAG}#g" ./user-data

if [ -z "${USER_DATA}" ] && [ -z "${VM_TAG}" ] && [ -z "${SSH_PUBKEY}" ]; then
    usage
fi

: "${USER_DATA:?no user-data supplied}" "${VM_TAG:?vm is not supplied}" "${SSH_PUBKEY:?ssh key is not supplied}"
test -s "${BASE_IMAGE_TAG}" || curl -fL# -o "${BASE_IMAGE_TAG}" "${BASE_IMAGE_LOC}"

qemu-img create -b $BASE_IMAGE_TAG -f qcow2 -F qcow2 "${VM_TAG}.img" 10G
echo -e "instance-id: ${VM_TAG}\nlocal-hostname: ${VM_TAG}" > meta-data
genisoimage -output "${VM_TAG}-cidata.iso" -V cidata -r -input-charset utf-8 -J user-data meta-data
virt-install \
    --name="${VM_TAG}" \
    --ram=2048 \
    --vcpus=2 \
    --import \
    --disk path="${VM_TAG}.img",format=qcow2 \
    --disk path="${VM_TAG}-cidata.iso",device=cdrom \
    --os-variant=ubuntu20.04 \
    --network bridge=k8s-br0,model=virtio \
    --graphics vnc,listen=0.0.0.0 \
    --noautoconsole

rm ./user-data
