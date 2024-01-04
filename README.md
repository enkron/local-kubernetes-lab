# prerequisites

first check [kvm](https://linux-kvm.org) (kernel-based virtual machine
for Linux on x86) is enabled in system

```bash
kvm-ok
```

```bash
sudo apt update
sudo apt install -y libvirt-daemon-system virtinst
```

check `qemu` emulator is installed

```bash
qemu-system-x86_64 --version
```

## cloud image

Cloud images use [cloud-init][1] method for instance initialisation
(eg. ubuntu cloud images archive https://cloud-images.ubuntu.com)

```bash
curl -fLO# http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
```

[user-data](/user-data) file contains instructions for bootstrapping
kubernetes toolchains along with dependencies like `containerd` or `cni`
plugins.

**NOTE**: *all package versions are currently hardcoded into the file, so
need to pay attention to maintenance*
**NOTE**: *change $SSH_PUBKEY variable to actual public key*

[1]: https://cloudinit.readthedocs.io/en/latest/index.html

## kubernetes [toolchains][2]
`kubeadm`: bootstrap a cluster. Should be installed on all the hosts,
`kubelet`: component that runs on all of machines in a cluster and does
           things like starting pods and containers,
`kubectl`: command line utility to talk to a cluster.

Note: `kubelet` won't work with a swap file.

[2]: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#k8s-install-0

## cluster initialization

After installing each component to the control plane host cluster could
initialized with the following command:

```bash
sudo kubeadm init
```

To start using the cluster run the following commands:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### deploy a pod network to the cluster

https://kubernetes.io/docs/concepts/cluster-administration/addons/

```bash
kubectl apply -f <POD_NETWORK>.yaml
```

for example:

```bash
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
```

This command deploys `weave net` that connects docker containers across
multiple hosts and enables their automatic discovery

# virsh tool commmands

`virsh` is a cli for virsh guest domains

list vms

```bash
virsh list --all
```

get vms addresses

```bash
virsh net-dhcp-leases --network default
```

shutdown vm gracefully

```bash
virsh shutdown <VM_TAG>
```
