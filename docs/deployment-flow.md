# CareSync — Full Deployment Flow

## End-to-End Order

```
Step 1:  terraform apply              --> VPC, EKS cluster, node groups, IAM
Step 2:  aws eks update-kubeconfig    --> Connect kubectl to EKS
Step 3:  Install ALB Controller       --> Required before ingress works
Step 4:  ./scripts/build-images.sh   --> Build + push Docker images
Step 5:  Update JWT secret in helm/caresync-config/values.yaml
Step 6:  helm: mongodb                --> StatefulSet + PVC + Service (deploy FIRST)
Step 7:  helm: caresync-config        --> Namespace + ConfigMap + Secret
Step 8:  helm: auth, patient, doctor, appointment
Step 9:  helm: frontend
Step 10: helm: ingress                --> Creates the AWS ALB (deploy LAST)
Step 11: kubectl get ingress          --> Get ALB DNS (wait 2-3 min)
```

---

## Step 1: Terraform Infrastructure

```bash
cd terraform-infra-repo
terraform init
terraform plan
terraform apply
# Note outputs: eks_cluster_name, alb_controller_role_arn, vpc_id
```

What Terraform creates: VPC, public/private subnets, NAT Gateway, EKS cluster,
node groups, IAM roles, OIDC provider.

MongoDB is NOT managed by Terraform — it runs as a StatefulSet inside EKS.

---

## Step 2: Connect kubectl to EKS

```bash
aws eks update-kubeconfig --region ap-south-1 --name caresync-cluster
kubectl get nodes   # Verify nodes are Ready
```

---

## Step 3: Install AWS Load Balancer Controller

```bash
helm repo add eks https://aws.github.io/eks-charts && helm repo update

CLUSTER_NAME="caresync-cluster"
AWS_REGION="ap-south-1"
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME \
  --query "cluster.resourcesVpcConfig.vpcId" --output text)

kubectl create serviceaccount aws-load-balancer-controller -n kube-system
kubectl annotate serviceaccount aws-load-balancer-controller -n kube-system \
  eks.amazonaws.com/role-arn=<ALB_CONTROLLER_ROLE_ARN>

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=$AWS_REGION \
  --set vpcId=$VPC_ID
```

See ingress-alb-guide.md for full details.

---

## Step 4: Build and Push Docker Images

```bash
cd caresync
docker login -u nandana2002
chmod +x scripts/build-images.sh
./scripts/build-images.sh latest
```

---

## Step 5: Update JWT Secret

Edit `helm/caresync-config/values.yaml`:
```yaml
secrets:
  jwtSecret: "$(openssl rand -base64 32)"
```

MongoDB URIs are already pre-configured to use `caresync-mongodb:27017`.
No manual changes needed for MongoDB.

---

## Steps 6–10: Deploy (Automated)

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh latest
```

Deploys in correct order:
1. MongoDB StatefulSet (waits until Ready)
2. ConfigMap + Secret
3. All backend services
4. Frontend
5. Ingress (creates ALB)

---

## Step 11: Get Application URL

```bash
kubectl get ingress caresync-ingress -n caresync
# ALB DNS appears in ADDRESS column after 2-3 minutes
```

---

## Updating a Service (Rolling Upgrade)

```bash
./scripts/build-images.sh v1.2.0
helm upgrade caresync-auth ./helm/auth \
  --namespace caresync --set image.tag=v1.2.0 --wait
```

---

## Teardown

```bash
./scripts/destroy.sh
# Then:
cd terraform-infra-repo && terraform destroy
```

WARNING: Destroying removes the PVC which deletes the EBS volume and all MongoDB data.
