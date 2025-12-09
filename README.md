# Kubernetes Cluster Setup using Kubeadm (Master + Worker on EC2)

## Overview
This repository provides production-ready automation scripts to set up a Kubernetes cluster using **kubeadm** on AWS EC2 instances.  
It includes scripts for:
- Common setup for both nodes  
- Master node initialization  
- Worker node join process  

## Folder Structure
```
kubeadm-setup/
├── setup-common.sh
├── setup-master.sh
├── setup-worker.sh
└── README.md
```

# 1. Prerequisites

## EC2 Requirements
| Node | Type | OS | CPU | RAM | Storage |
|------|------|----|-----|-----|----------|
| Master | t3.medium | Ubuntu 22.04 | 2 vCPU | 4 GB | 30 GB |
| Worker | t3.medium | Ubuntu 22.04 | 2 vCPU | 4 GB | 30 GB |

## Security Group Rules
| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH |
| 6443 | TCP | Kubernetes API |
| 10250 | TCP | Kubelet |
| 30000–32767 | TCP | NodePort |
| 179 | TCP | Calico |

# 2. Scripts

## setup-common.sh
- Disables swap  
- Loads kernel modules  
- Configures sysctl  
- Installs containerd  
- Installs kubeadm, kubelet, kubectl  

## setup-master.sh
- Initializes control-plane  
- Sets kubectl config  
- Installs Calico CNI  
- Outputs join command  

## setup-worker.sh
- Accepts join command  
- Joins node to master  

# 3. Usage

## Step 1: Upload & make executable
```
chmod +x setup-common.sh setup-master.sh setup-worker.sh
```

## Step 2: Run common script
Master:
```
./setup-common.sh
```
Worker:
```
./setup-common.sh
```

## Step 3: Initialize master
```
./setup-master.sh
```

## Step 4: Join worker
```
./setup-worker.sh "<join command>"
```

## Step 5: Verify
```
kubectl get nodes
kubectl get pods -A
```

# 4. Production Hardening
- Enable audit logs  
- Encrypt secrets at rest  
- Use etcd backup strategy  
- Restrict SSH  
- Enable Calico network policies  
- Configure metrics server  

# 5. Support
For further automation (Terraform, Ansible, CI/CD), enhancements can be added anytime.
