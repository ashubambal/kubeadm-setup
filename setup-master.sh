#!/bin/bash
set -e

POD_CIDR="192.168.0.0/16"
CALICO_VERSION="v3.27.3"

echo "==== Initializing Kubernetes Master Node ===="
sudo kubeadm init --pod-network-cidr=$POD_CIDR

echo "==== Setting up kubectl for current user ===="
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "==== Installing Calico CNI (Stable: $CALICO_VERSION) ===="
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/calico.yaml

echo "==== Waiting for Calico components to start ===="
sleep 10
kubectl get pods -n kube-system

echo "==== Kubernetes Master Initialization Complete ===="

echo ""
echo "==== COPY BELOW WORKER JOIN COMMAND ===="
sudo kubeadm token create --print-join-command
