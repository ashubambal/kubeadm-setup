# Kubernetes Cluster Setup using kubeadm (Ubuntu)

A complete guide to set up a production-grade Kubernetes cluster using kubeadm on Ubuntu 20.04 / 22.04 / 24.04.  
This document includes all required prerequisites, configuration steps for both master and worker nodes, and common troubleshooting commands.

## 1. Prerequisites

### System Requirements
| Component | Master | Worker |
|----------|--------|--------|
| CPU | 2 vCPU+ | 1 vCPU+ |
| RAM | 2–4 GB | 2 GB |
| Storage | 20 GB+ | 20 GB+ |
| Network | Nodes must ping each other | Required |

### Mandatory Setup on All Nodes

#### Update System
```bash
sudo apt update && sudo apt upgrade -y
```

#### Disable Swap
```bash
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
```

#### Load Required Kernel Modules
```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
```

#### Configure Network Parameters
```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
```

### Install containerd Runtime
```bash
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

### Install kubeadm, kubelet, kubectl
```bash
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key   | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /"   | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

## 2. Common Commands on All Nodes

### Service Status
```bash
systemctl status kubelet
systemctl status containerd
```

### Restart Services
```bash
sudo systemctl restart kubelet
sudo systemctl restart containerd
```

### Log Monitoring
```bash
journalctl -u kubelet -f
journalctl -u containerd -f
```

## 3. Master Node Setup

### Initialize Kubernetes Control Plane
```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

### Configure kubectl
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Install Calico CNI Network Plugin
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml
```

### Verify Master Node
```bash
kubectl get nodes
kubectl get pods -A
```

## 4. Worker Node Setup

### Join Worker Node to the Cluster
```bash
sudo kubeadm join <MASTER-IP>:6443 --token <TOKEN>   --discovery-token-ca-cert-hash sha256:<HASH>
```

### Get Join Command If Lost
```bash
sudo kubeadm token create --print-join-command
```

### Verify in Master
```bash
kubectl get nodes -o wide
```

## 5. Troubleshooting & Fixes

### Kubelet Crash Loop: Missing config.yaml
Error:
```
failed to read kubelet config file "/var/lib/kubelet/config.yaml"
```

Fix: Run kubeadm init (master) or kubeadm join (worker).

### Reset Failed Cluster
```bash
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo systemctl restart kubelet
```

### Delete CNI Interfaces
```bash
sudo ip link delete cni0
sudo ip link delete flannel.1 2>/dev/null
```

## 6. Test Deployment

### Deploy Nginx
```bash
kubectl create deployment nginx --image=nginx
```

### Expose Nginx as NodePort
```bash
kubectl expose deployment nginx --port=80 --type=NodePort
```

### Check Service
```bash
kubectl get svc
```

## Notes
- kubelet restarts until kubeadm init/join generates its config.
