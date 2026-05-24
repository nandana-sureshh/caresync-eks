#!/usr/bin/env bash
# Destroy all CareSync resources from EKS (reverse deploy order)
set -euo pipefail
echo "========================================"
echo " CareSync — Destroying EKS Stack"
echo " WARNING: All data including MongoDB will be deleted!"
echo "========================================"
echo ""
read -rp "Type 'yes' to confirm: " CONFIRM
[[ "$CONFIRM" != "yes" ]] && echo "Aborted." && exit 0

for release in caresync-ingress caresync-frontend caresync-appointment caresync-doctor caresync-patient caresync-auth caresync-config caresync-mongodb; do
  echo "-- Uninstalling $release..."
  helm uninstall "$release" --namespace caresync 2>/dev/null \
    && echo "   Removed $release" \
    || echo "   Not found: $release (skipping)"
done

echo ""
echo "-- Deleting namespace 'caresync' (also removes PVC/EBS volume)..."
kubectl delete namespace caresync --ignore-not-found=true

echo ""
echo "========================================"
echo " Stack destroyed. EBS volume also deleted (PVC lifecycle)."
echo "========================================"
