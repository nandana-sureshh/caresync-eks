# AWS ALB Ingress Controller Guide

## What It Does
The AWS Load Balancer Controller reads your Ingress resource and creates a real ALB in AWS.
Without it, no external access to your app.

## Installation Steps

### 1. Add EKS Helm Repo
```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

### 2. Get Cluster Details
```bash
CLUSTER_NAME="caresync-cluster"
AWS_REGION="ap-south-1"
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.resourcesVpcConfig.vpcId" --output text)
```

### 3. Get ALB Controller IAM Role ARN (from Terraform output)
```bash
cd terraform-infra-repo && terraform output alb_controller_role_arn
```

### 4. Create Service Account
```bash
kubectl create serviceaccount aws-load-balancer-controller -n kube-system
kubectl annotate serviceaccount aws-load-balancer-controller -n kube-system \
  eks.amazonaws.com/role-arn=<ALB_CONTROLLER_ROLE_ARN>
```

### 5. Install via Helm
```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=$AWS_REGION \
  --set vpcId=$VPC_ID
```

### 6. Verify
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
# Should show READY 2/2
```

### 7. Deploy Ingress
```bash
helm upgrade --install caresync-ingress ./helm/ingress --namespace caresync
```

### 8. Get ALB DNS
```bash
kubectl get ingress caresync-ingress -n caresync
# ADDRESS column = your ALB DNS (takes 2-3 minutes)
```

## Key Annotations Explained

```yaml
kubernetes.io/ingress.class: alb                    # Use AWS ALB
alb.ingress.kubernetes.io/scheme: internet-facing   # Public ALB
alb.ingress.kubernetes.io/target-type: ip           # Route to pod IPs
alb.ingress.kubernetes.io/healthcheck-path: /health # ALB health check
```

## Adding HTTPS (Optional)
1. Create ACM certificate for your domain
2. Set certificateArn in helm/ingress/values.yaml
3. helm upgrade caresync-ingress ./helm/ingress --namespace caresync
