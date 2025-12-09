#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./setup-worker.sh <JOIN-COMMAND>"
  echo "Example:"
  echo "./setup-worker.sh \"kubeadm join <master-ip>:6443 --token xyz --discovery-token-ca-cert-hash sha256:abcd\""
  exit 1
fi

echo "==== Joining Worker Node to Master ===="
sudo $1

echo "==== Worker setup completed ===="
