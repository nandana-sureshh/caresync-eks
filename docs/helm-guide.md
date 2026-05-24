# Helm Guide

## Chart Overview (Deploy in this order)

| # | Chart | Release Name | Purpose |
|---|---|---|---|
| 1 | helm/mongodb | caresync-mongodb | MongoDB StatefulSet + PVC + ClusterIP |
| 2 | helm/caresync-config | caresync-config | Namespace + ConfigMap + Secret |
| 3 | helm/auth | caresync-auth | Auth service |
| 4 | helm/patient | caresync-patient | Patient service |
| 5 | helm/doctor | caresync-doctor | Doctor service |
| 6 | helm/appointment | caresync-appointment | Appointment service |
| 7 | helm/frontend | caresync-frontend | Frontend |
| 8 | helm/ingress | caresync-ingress | AWS ALB Ingress (deploy LAST) |

---

## MongoDB Chart (helm/mongodb)

Deploys ONE shared MongoDB StatefulSet with:
- 1 PersistentVolumeClaim (10Gi, gp2 EBS in EKS)
- 1 ClusterIP Service named `caresync-mongodb`
- Services connect via: `mongodb://caresync-mongodb:27017/<dbname>`

---

## Before Deploying — Only One Change Required

Edit `helm/caresync-config/values.yaml`:

```yaml
secrets:
  jwtSecret: "replace-with-strong-secret"   # openssl rand -base64 32
```

MongoDB URIs are pre-configured. No changes needed.

---

## Deploy (Automated)

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh latest
```

## Deploy (Manual)

```bash
# 1. MongoDB FIRST
helm upgrade --install caresync-mongodb ./helm/mongodb --namespace caresync --create-namespace --wait

# 2. Config
helm upgrade --install caresync-config ./helm/caresync-config --wait

# 3. Services
helm upgrade --install caresync-auth       ./helm/auth       --namespace caresync --set image.tag=latest --wait
helm upgrade --install caresync-patient    ./helm/patient    --namespace caresync --set image.tag=latest --wait
helm upgrade --install caresync-doctor     ./helm/doctor     --namespace caresync --set image.tag=latest --wait
helm upgrade --install caresync-appointment ./helm/appointment --namespace caresync --set image.tag=latest --wait

# 4. Frontend
helm upgrade --install caresync-frontend   ./helm/frontend   --namespace caresync --set image.tag=latest --wait

# 5. Ingress LAST
helm upgrade --install caresync-ingress    ./helm/ingress    --namespace caresync --wait
```

## Useful Commands

```bash
helm list -n caresync                              # List releases
helm template caresync-mongodb ./helm/mongodb      # Dry run MongoDB chart
helm history caresync-auth -n caresync             # Release history
helm rollback caresync-auth 1 -n caresync          # Roll back
```

## Check MongoDB is Running

```bash
kubectl get statefulset -n caresync
kubectl get pvc -n caresync
kubectl logs caresync-mongodb-0 -n caresync
```
