#!/usr/bin/env bash
# CareSync Kubernetes health check
set -euo pipefail
NS="caresync"
echo "=== EKS Nodes ==="
kubectl get nodes -o wide
echo "=== Pods ==="
kubectl get pods -n "$NS" -o wide
echo "=== Services ==="
kubectl get svc -n "$NS"
echo "=== Ingress ==="
kubectl get ingress -n "$NS"
echo "=== Helm Releases ==="
helm list -n "$NS"
echo "=== Events (last 10) ==="
kubectl get events -n "$NS" --sort-by=".lastTimestamp" | tail -10
