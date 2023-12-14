#!/bin/bash

for img in "${@}"; do
    virsh destroy --domain "${img}"
    virsh undefine --domain "${img}"
    rm -rf "${img}.img"
    rm -rf "${img}-cidata.iso"
done
virsh pool-destroy --pool $(basename $PWD)
virsh pool-undefine --pool $(basename $PWD)
rm -rf meta-data
