#!/bin/bash
set -e

POD_CIDR="192.168.0.0/16"

echo "==== Initializing Kubernetes Master Node ===="
sudo kubeadm init --pod-network-cidr=$POD_CIDR

echo "==== Setting up kubectl for current user ===="
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "==== Installing Calico CNI ===="
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml

echo "==== Kubernetes Master Initialization Complete ===="

echo ""
echo "==== COPY BELOW WORKER JOIN COMMAND ===="
sudo kubeadm token create --print-join-command
