#!/usr/bin/env bash
# Build and push all CareSync Docker images to Docker Hub
# Usage: ./scripts/build-images.sh [TAG]
set -euo pipefail
REGISTRY="nandana2002"
TAG="${1:-latest}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SERVICES=(
  "auth-service:caresync-auth"
  "patient-service:caresync-patient"
  "doctor-service:caresync-doctor"
  "appointment-service:caresync-appointment"
  "frontend:caresync-frontend"
)
echo "Building all images with tag: $TAG"
for entry in "${SERVICES[@]}"; do
  SERVICE_DIR="${entry%%:*}"
  IMAGE_NAME="${entry##*:}"
  FULL_IMAGE="$REGISTRY/$IMAGE_NAME:$TAG"
  echo "-- Building $FULL_IMAGE"
  docker build -t "$FULL_IMAGE" "$REPO_ROOT/services/$SERVICE_DIR"
  echo "-- Pushing $FULL_IMAGE"
  docker push "$FULL_IMAGE"
done
echo "All images built and pushed. Tag: $TAG"
