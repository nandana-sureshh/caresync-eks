# CareSync — Architecture Overview

## Deployment Architecture

```
Internet
    |
    v
AWS Application Load Balancer (caresync-alb)
    |  Path-based routing via AWS ALB Ingress Controller
    |
    |-- /api/auth/*          --> caresync-auth-service:4001
    |-- /api/patients/*      --> caresync-patient-service:4002
    |-- /api/doctors/*       --> caresync-doctor-service:4003
    |-- /api/appointments/*  --> caresync-appointment-service:4004
    `-- /*                   --> caresync-frontend-service:8080

    All running inside Kubernetes namespace: caresync (EKS)
         |
         | mongodb://caresync-mongodb:27017/<dbname>
         v
    MongoDB StatefulSet (caresync-mongodb)
         | One PVC backed by AWS EBS (gp2, 10Gi)
         | Four logical databases:
         |-- authdb
         |-- patientdb
         |-- doctordb
         `-- appointmentdb
```

---

## Services

| Service | Port | Route | Image |
|---|---|---|---|
| auth-service | 4001 | /api/auth | nandana2002/caresync-auth |
| patient-service | 4002 | /api/patients | nandana2002/caresync-patient |
| doctor-service | 4003 | /api/doctors | nandana2002/caresync-doctor |
| appointment-service | 4004 | /api/appointments | nandana2002/caresync-appointment |
| frontend | 8080 | / | nandana2002/caresync-frontend |

---

## MongoDB Architecture

### Kubernetes (EKS)
- **ONE shared MongoDB StatefulSet** (`caresync-mongodb`) inside Kubernetes
- **ONE PersistentVolumeClaim** (`caresync-mongodb-pvc`) backed by AWS EBS (gp2, 10Gi)
- **Four logical databases** — authdb, patientdb, doctordb, appointmentdb
- All services connect using Kubernetes DNS: `caresync-mongodb:27017`
- Data persists across pod restarts and redeployments

### Local (docker-compose)
- **ONE shared `mongo:7` container** — service name: `mongo`
- Same four logical databases
- Services connect via Docker DNS: `mongo:27017`

---

## Helm Charts (deploy order)

| # | Chart | Release Name | Purpose |
|---|---|---|---|
| 1 | helm/mongodb | caresync-mongodb | StatefulSet + PVC + ClusterIP Service |
| 2 | helm/caresync-config | caresync-config | Namespace + ConfigMap + Secret |
| 3 | helm/auth | caresync-auth | Auth deployment + ClusterIP |
| 4 | helm/patient | caresync-patient | Patient deployment + ClusterIP |
| 5 | helm/doctor | caresync-doctor | Doctor deployment + ClusterIP |
| 6 | helm/appointment | caresync-appointment | Appointment deployment + ClusterIP |
| 7 | helm/frontend | caresync-frontend | Frontend deployment + ClusterIP |
| 8 | helm/ingress | caresync-ingress | AWS ALB Ingress — deploy LAST |

---

## Two-Repo Split

```
terraform-infra-repo/   --> Creates AWS infrastructure (VPC, EKS cluster, node groups, IAM)
caresync/               --> Deploys application workloads into EKS (this repo)
```

Terraform does NOT manage MongoDB — it runs as a StatefulSet inside EKS.

---

## Security

- All Node.js containers run as non-root (uid 1000)
- nginx-unprivileged runs as uid 101
- JWT_SECRET stored in Kubernetes Secret, not ConfigMap
- MongoDB has no public endpoint — ClusterIP only inside the cluster
- All services use ClusterIP — external access only via ALB Ingress
