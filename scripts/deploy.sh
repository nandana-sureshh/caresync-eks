#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# deploy.sh — Deploy full CareSync stack to EKS
#
# Deployment order (critical):
#   1. mongodb       — StatefulSet + PVC + Service (must be Ready before services)
#   2. caresync-config — Namespace + ConfigMap + Secret
#   3. auth           — Auth microservice
#   4. patient        — Patient microservice
#   5. doctor         — Doctor microservice
#   6. appointment    — Appointment microservice
#   7. frontend       — React frontend
#   8. ingress        — AWS ALB Ingress (creates load balancer — deploy LAST)
#
# Usage:
#   ./scripts/deploy.sh [TAG]
#   ./scripts/deploy.sh latest       (default)
#   ./scripts/deploy.sh v1.2.0
#
# Prerequisites:
#   - kubectl connected to EKS cluster (aws eks update-kubeconfig ...)
#   - Helm 3 installed
#   - AWS Load Balancer Controller installed in kube-system
#   - JWT secret updated in helm/caresync-config/values.yaml
#   - Docker images pushed to Docker Hub
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

TAG="${1:-latest}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELM_DIR="$(dirname "$SCRIPT_DIR")/helm"

echo "========================================"
echo " CareSync — Deploying to EKS"
echo " Image Tag : $TAG"
echo "========================================"

# ── 1. MongoDB (StatefulSet + PVC + Service) ──────────────────────────────────
echo ""
echo "[1/8] Deploying MongoDB StatefulSet..."
helm upgrade --install caresync-mongodb "$HELM_DIR/mongodb" \
  --namespace caresync \
  --create-namespace \
  --wait --timeout 180s

# ── 2. Shared config (ConfigMap + Secret) ────────────────────────────────────
echo ""
echo "[2/8] Deploying caresync-config (ConfigMap + Secret)..."
helm upgrade --install caresync-config "$HELM_DIR/caresync-config" \
  --wait --timeout 60s

# ── 3. Auth Service ───────────────────────────────────────────────────────────
echo ""
echo "[3/8] Deploying auth-service..."
helm upgrade --install caresync-auth "$HELM_DIR/auth" \
  --namespace caresync \
  --set image.tag="$TAG" \
  --wait --timeout 120s

# ── 4. Patient Service ────────────────────────────────────────────────────────
echo ""
echo "[4/8] Deploying patient-service..."
helm upgrade --install caresync-patient "$HELM_DIR/patient" \
  --namespace caresync \
  --set image.tag="$TAG" \
  --wait --timeout 120s

# ── 5. Doctor Service ─────────────────────────────────────────────────────────
echo ""
echo "[5/8] Deploying doctor-service..."
helm upgrade --install caresync-doctor "$HELM_DIR/doctor" \
  --namespace caresync \
  --set image.tag="$TAG" \
  --wait --timeout 120s

# ── 6. Appointment Service ────────────────────────────────────────────────────
echo ""
echo "[6/8] Deploying appointment-service..."
helm upgrade --install caresync-appointment "$HELM_DIR/appointment" \
  --namespace caresync \
  --set image.tag="$TAG" \
  --wait --timeout 120s

# ── 7. Frontend ───────────────────────────────────────────────────────────────
echo ""
echo "[7/8] Deploying frontend..."
helm upgrade --install caresync-frontend "$HELM_DIR/frontend" \
  --namespace caresync \
  --set image.tag="$TAG" \
  --wait --timeout 120s

# ── 8. Ingress (creates the ALB) ──────────────────────────────────────────────
echo ""
echo "[8/8] Deploying ingress (AWS ALB)..."
helm upgrade --install caresync-ingress "$HELM_DIR/ingress" \
  --namespace caresync \
  --wait --timeout 180s

echo ""
echo "========================================"
echo " Deployment complete!"
echo ""
echo " Fetching ALB DNS (may take 2-3 min to become active)..."
kubectl get ingress caresync-ingress -n caresync \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null \
  && echo "" || echo " (ALB provisioning in progress)"
echo "========================================"
