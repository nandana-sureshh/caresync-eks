# Troubleshooting Guide

## MongoDB Not Ready / Services Fail to Connect

```bash
# Check StatefulSet
kubectl get statefulset caresync-mongodb -n caresync
kubectl get pods -n caresync | grep mongo
kubectl logs caresync-mongodb-0 -n caresync

# Check PVC is bound
kubectl get pvc -n caresync
# STATUS should be: Bound
```

| Problem | Cause | Fix |
|---|---|---|
| PVC stuck in Pending | gp2 StorageClass not available | Check: kubectl get storageclass |
| Pod CrashLoopBackOff | EBS volume not attached | Describe pod for events |
| Connection refused from app | MongoDB not ready yet | Wait for StatefulSet to be Ready 1/1 |

If PVC stays Pending in EKS, verify the gp2 StorageClass exists:
```bash
kubectl get storageclass
# Should show: gp2 (default) or gp3
```
If not present: `kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/examples/kubernetes/dynamic-provisioning/manifests/storageclass.yaml`

---

## Pods CrashLoopBackOff

```bash
kubectl describe pod <pod-name> -n caresync
kubectl logs <pod-name> -n caresync
```

| Error | Fix |
|---|---|
| MongoServerError: connect ECONNREFUSED | MongoDB pod not ready — wait or check statefulset |
| JWT_SECRET not defined | caresync-secrets missing — redeploy caresync-config |
| ImagePullBackOff | Push image first: ./scripts/build-images.sh |

---

## ConfigMap / Secret Missing

```bash
kubectl get configmap caresync-config -n caresync
kubectl get secret caresync-secrets -n caresync
# If missing:
helm upgrade --install caresync-config ./helm/caresync-config --wait
```

---

## ALB Not Provisioned

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=50
```
Causes: ALB Controller not installed, IAM role missing, public subnets missing tag `kubernetes.io/role/elb=1`

---

## 503 from ALB

```bash
kubectl get pods -n caresync              # All must be Running + Ready
kubectl describe svc caresync-auth-service -n caresync
kubectl describe ingress caresync-ingress -n caresync
```

---

## Wrong Frontend API URLs

Rebuild with correct ALB DNS as base URL:
```bash
docker build \
  --build-arg REACT_APP_AUTH_URL=http://<ALB-DNS>/api/auth \
  --build-arg REACT_APP_PATIENT_URL=http://<ALB-DNS>/api/patients \
  --build-arg REACT_APP_DOCTOR_URL=http://<ALB-DNS>/api/doctors \
  --build-arg REACT_APP_APPOINTMENT_URL=http://<ALB-DNS>/api/appointments \
  -t nandana2002/caresync-frontend:latest ./services/frontend
docker push nandana2002/caresync-frontend:latest
helm upgrade caresync-frontend ./helm/frontend --namespace caresync --set image.tag=latest
```

---

## General Debug

```bash
kubectl get events -n caresync --sort-by=".lastTimestamp"
kubectl get all -n caresync
kubectl exec -it <pod-name> -n caresync -- sh
```
