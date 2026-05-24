# Terraform Infrastructure Setup

## Overview

The Terraform infra repo creates all AWS infrastructure.
MongoDB runs as a StatefulSet INSIDE EKS — Terraform does NOT manage MongoDB.

```
terraform-infra-repo/    --> Creates: VPC, subnets, EKS, IAM, OIDC provider
caresync/ (this repo)    --> Deploys: MongoDB StatefulSet + all app services into EKS
```

---

## What Terraform Creates

| Resource | Purpose |
|---|---|
| VPC | Isolated network |
| Public subnets (x2) | ALB, NAT Gateway |
| Private subnets (x2) | EKS worker nodes |
| Internet Gateway | Public subnet internet |
| NAT Gateway | Private subnet outbound traffic |
| EKS Cluster | Kubernetes control plane |
| EKS Node Group | EC2 worker nodes (e.g. t3.medium x2) |
| IAM Roles | EKS cluster role, node role, ALB Controller role |
| OIDC Provider | Required for ALB Controller IRSA |

MongoDB is NOT in this list. It is deployed as a Kubernetes StatefulSet by the
caresync Helm chart (helm/mongodb), and data is stored in an AWS EBS volume
automatically provisioned by the gp2 StorageClass.

---

## Apply Terraform

```bash
aws configure   # Enter credentials, region, json output

cd terraform-infra-repo
terraform init
terraform plan
terraform apply   # Type 'yes' when prompted

# Get outputs
terraform output
```

## Key Outputs

| Output | Used For |
|---|---|
| eks_cluster_name | aws eks update-kubeconfig |
| alb_controller_role_arn | ALB Controller Helm install |
| vpc_id | ALB Controller Helm install |

---

## After Terraform — Next Steps

1. Connect kubectl to EKS (see cluster-setup.md)
2. Install ALB Controller (see ingress-alb-guide.md)
3. Build and push Docker images
4. Deploy via: ./scripts/deploy.sh latest

No MongoDB IP or EC2 configuration required.
MongoDB deploys automatically via helm/mongodb chart.
