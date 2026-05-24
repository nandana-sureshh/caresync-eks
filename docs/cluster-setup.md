# EKS Cluster Setup Guide

## Install Required Tools

### AWS CLI
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
aws --version
```

### kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/
kubectl version --client
```

### Helm 3
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### eksctl (optional)
```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

---

## Connect kubectl to EKS

```bash
aws configure
# AWS Access Key ID: <your-key>
# Secret Access Key: <your-secret>
# Region: ap-south-1
# Output format: json

aws eks update-kubeconfig --region ap-south-1 --name caresync-cluster

# Verify
kubectl get nodes          # Should show Ready nodes
kubectl get namespaces
```

---

## Install AWS Load Balancer Controller

Required before deploying the ingress chart. See ingress-alb-guide.md.

---

## Deploy CareSync (Full Stack)

MongoDB runs inside EKS — no external database setup needed.

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh latest
```

Deploy order handled automatically:
1. MongoDB StatefulSet
2. Config (ConfigMap + Secret)
3. Backend services
4. Frontend
5. Ingress (ALB)

---

## Useful kubectl Commands

```bash
kubectl get pods -n caresync -w              # Watch pods start up
kubectl get statefulset -n caresync          # Check MongoDB
kubectl get pvc -n caresync                  # Check EBS volume claim
kubectl get ingress -n caresync              # Get ALB DNS
kubectl describe pod <name> -n caresync      # Debug pod issues
kubectl logs <name> -n caresync              # Pod logs
kubectl get all -n caresync                  # Full overview
```
