# Docker Guide

## Build All Images

```bash
chmod +x scripts/build-images.sh
./scripts/build-images.sh latest
# Or with a tag:
./scripts/build-images.sh v1.2.0
```

## Build a Single Image

```bash
docker build -t nandana2002/caresync-auth:latest ./services/auth-service
```

## Build Frontend (with API URLs)

```bash
docker build \
  --build-arg REACT_APP_AUTH_URL=http://<ALB-DNS>/api/auth \
  --build-arg REACT_APP_PATIENT_URL=http://<ALB-DNS>/api/patients \
  --build-arg REACT_APP_DOCTOR_URL=http://<ALB-DNS>/api/doctors \
  --build-arg REACT_APP_APPOINTMENT_URL=http://<ALB-DNS>/api/appointments \
  -t nandana2002/caresync-frontend:latest \
  ./services/frontend
```

IMPORTANT: Frontend API URLs are baked in at build time. Use the ALB DNS name for EKS.

## Push to Docker Hub

```bash
docker login -u nandana2002
docker push nandana2002/caresync-auth:latest
```

## Images

| Image | Port | Base |
|---|---|---|
| nandana2002/caresync-auth | 4001 | node:20-alpine (non-root uid 1000) |
| nandana2002/caresync-patient | 4002 | node:20-alpine (non-root uid 1000) |
| nandana2002/caresync-doctor | 4003 | node:20-alpine (non-root uid 1000) |
| nandana2002/caresync-appointment | 4004 | node:20-alpine (non-root uid 1000) |
| nandana2002/caresync-frontend | 8080 | nginx-unprivileged:1.25-alpine (uid 101) |
