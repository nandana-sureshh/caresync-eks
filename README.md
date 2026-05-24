# CareSync — Healthcare Appointment Platform

Microservices-based healthcare appointment system deployed on Amazon EKS
with Helm, AWS ALB, and a shared MongoDB StatefulSet.

---

## Architecture

- **4 Node.js microservices** — auth, patient, doctor, appointment
- **1 React frontend** — served by nginx (unprivileged, port 8080)
- **1 MongoDB StatefulSet** — shared inside Kubernetes, EBS-backed (10Gi gp2)
- **All services: ClusterIP** — no public ports except via ALB Ingress
- **AWS ALB** — single external entry point via path-based routing

See [docs/architecture.md](docs/architecture.md) for the full diagram.

---

## Repository Structure

```
caresync/
├── services/
│   ├── auth-service/          # Node.js — port 4001
│   ├── patient-service/       # Node.js — port 4002
│   ├── doctor-service/        # Node.js — port 4003
│   ├── appointment-service/   # Node.js — port 4004
│   └── frontend/              # React + nginx — port 8080
├── helm/
│   ├── mongodb/               # StatefulSet + PVC + Service (deploy FIRST)
│   ├── caresync-config/       # Namespace + ConfigMap + Secret
│   ├── auth/                  # Auth service chart
│   ├── patient/               # Patient service chart
│   ├── doctor/                # Doctor service chart
│   ├── appointment/           # Appointment service chart
│   ├── frontend/              # Frontend chart
│   └── ingress/               # AWS ALB Ingress (deploy LAST)
├── scripts/
│   ├── build-images.sh        # Build + push all Docker images
│   ├── deploy.sh              # Full deploy to EKS (correct order)
│   ├── destroy.sh             # Tear down everything
│   └── health-check.sh        # Check cluster state
├── docs/                      # 10 complete guides
├── docker-compose.yml         # Local dev — 1 shared mongo:7 + 5 services
├── .gitignore
├── LICENSE
└── README.md
```

---

## Quick Start — Local Development

```bash
docker-compose up --build
open http://localhost:8080
```

See [docs/local-development.md](docs/local-development.md) for more.

---

## Deploy to EKS

### Prerequisites
- Terraform infra applied (EKS cluster running)
- kubectl connected to EKS
- AWS Load Balancer Controller installed
- Docker images pushed to Docker Hub

### 1. Set JWT Secret

Edit `helm/caresync-config/values.yaml`:
```yaml
secrets:
  jwtSecret: "$(openssl rand -base64 32)"
```

### 2. Build and Push Images

```bash
chmod +x scripts/build-images.sh
./scripts/build-images.sh latest
```

### 3. Deploy (all 8 components in order)

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh latest
```

This automatically deploys:
1. MongoDB StatefulSet (EBS-backed PVC)
2. ConfigMap + Secret
3. All backend services
4. Frontend
5. ALB Ingress

### 4. Get Application URL

```bash
kubectl get ingress caresync-ingress -n caresync
# Wait 2-3 minutes for ALB to become active
```

---

## Documentation

| Guide | Description |
|---|---|
| [architecture.md](docs/architecture.md) | System design, MongoDB StatefulSet, service map |
| [local-development.md](docs/local-development.md) | Run with docker-compose |
| [docker-guide.md](docs/docker-guide.md) | Build and push Docker images |
| [helm-guide.md](docs/helm-guide.md) | Helm chart reference + deploy order |
| [terraform-setup.md](docs/terraform-setup.md) | Infrastructure provisioning |
| [cluster-setup.md](docs/cluster-setup.md) | EKS connection and tool setup |
| [ingress-alb-guide.md](docs/ingress-alb-guide.md) | AWS ALB Controller install |
| [deployment-flow.md](docs/deployment-flow.md) | Full step-by-step deployment |
| [application-setup.md](docs/application-setup.md) | Env vars + MongoDB URIs reference |
| [troubleshooting.md](docs/troubleshooting.md) | Common issues and fixes |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Node.js + Express + Mongoose |
| Frontend | React 18 + nginx-unprivileged |
| Database | MongoDB 7 (StatefulSet inside EKS, EBS-backed) |
| Containers | Docker (multi-stage, non-root) |
| Orchestration | Kubernetes (Amazon EKS) |
| Package Manager | Helm 3 |
| Load Balancer | AWS ALB (via Ingress Controller) |
| Infra | Terraform (separate repo) |
