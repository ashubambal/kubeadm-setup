# Dynamic AWS EBS StorageClass on kubeadm Cluster

This guide explains how to enable dynamic AWS EBS provisioning on a kubeadm-based Kubernetes cluster running on EC2 instances.

---

## 1. Prerequisites

- Two EC2 instances (Master + Worker)
- IAM Role attached to both nodes: **AmazonEKS_EBS_CSI_DriverRole**
- kubeadm + kubectl installed
- Security groups allowing communication between nodes

---

## 2. Install Calico CNI (Networking)

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml
watch kubectl get pods -A
```

---

## 3. Install the AWS EBS CSI Driver (Helm)

### Install Helm
```bash
curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

### Add CSI driver chart repo
```bash
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
```

### Install the driver
```bash
helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  -n kube-system \
  --set controller.serviceAccount.create=true \
  --set controller.serviceAccount.annotations."eks\\.amazonaws\\.com/role-arn"="arn:aws:iam::041326371952:role/AmazonEKS_EBS_CSI_DriverRole"
```

Verify pods:
```bash
kubectl get pods -n kube-system | grep ebs
```

---

## 4. Create gp3 StorageClass

Create `ebs-gp3-sc.yaml`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  csi.storage.k8s.io/fstype: ext4
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

Apply:

```bash
kubectl apply -f ebs-gp3-sc.yaml
kubectl get storageclass
```

---

## 5. Test Dynamic PVC Provisioning

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 4Gi
  storageClassName: gp3
EOF
```

Check PVC:
```bash
kubectl describe pvc test-pvc
```

Expected:

- `VolumeHandle: vol-xxxx` appears  
- New EBS gp3 volume appears in AWS console  

---

## 6. Deploy NGINX with EBS-backed PVC

Create `nginx-ebs.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
          volumeMounts:
            - name: nginx-storage
              mountPath: /usr/share/nginx/html
      volumes:
        - name: nginx-storage
          persistentVolumeClaim:
            claimName: nginx-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

Apply:

```bash
kubectl apply -f nginx-ebs.yaml
```

Access:

```
http://<EC2-PUBLIC-IP>:30080
```

---

## 7. Validation Checklist

✔ PVC created  
✔ EBS volume provisioned automatically  
✔ NGINX pod mounted the EBS volume  
✔ Service accessible externally  

---

## 8. Summary

Your kubeadm cluster now supports:

- AWS EBS dynamic provisioning  
- gp3 default StorageClass  
- Persistent storage for workloads  
