
# prerequisites

```bash
sudo apt update
sudo apt install -y libvirt-daemon-system virtinst
```

## cloud image

Cloud images use [cloud-init][1] method for instance initialisation
(eg. ubuntu cloud images archive https://cloud-images.ubuntu.com)

```bash
curl -fLO# http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
```

[1]: https://cloudinit.readthedocs.io/en/latest/index.html

# commmands

list VMs

```bash
virsh list --all
```

get VMs addresses

```bash
virsh net-dhcp-leases --network default
```
