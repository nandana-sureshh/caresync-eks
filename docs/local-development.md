# Local Development Guide

## Start Full Stack

```bash
docker-compose up --build
```

Starts:
- ONE shared MongoDB container (mongo:7) — service name: `mongo`
- auth-service on port 4001
- patient-service on port 4002
- doctor-service on port 4003
- appointment-service on port 4004
- frontend (nginx) on port 8080

### MongoDB Connection (local)
All services connect to MongoDB via Docker DNS:
```
mongodb://mongo:27017/authdb
mongodb://mongo:27017/patientdb
mongodb://mongo:27017/doctordb
mongodb://mongo:27017/appointmentdb
```

### MongoDB Connection (Kubernetes/EKS)
In EKS, services connect via Kubernetes DNS:
```
mongodb://caresync-mongodb:27017/authdb
```
This is configured automatically in the ConfigMap — no manual changes needed.

---

## Access

| URL | Service |
|---|---|
| http://localhost:8080 | Frontend |
| http://localhost:4001/health | Auth health check |
| http://localhost:4002/health | Patient health check |
| http://localhost:4003/health | Doctor health check |
| http://localhost:4004/health | Appointment health check |
| mongodb://localhost:27017 | MongoDB (for Compass/CLI) |

---

## Common Commands

```bash
docker-compose logs -f auth-service       # Live logs
docker-compose restart patient-service    # Restart one service
docker-compose down                       # Stop all
docker-compose down -v                    # Stop + wipe MongoDB data
```

---

## Without Docker (Raw Node)

```bash
docker run -d -p 27017:27017 mongo:7

cd services/auth-service && cp .env.example .env && npm install && npm run dev
cd services/patient-service && cp .env.example .env && npm install && npm run dev
cd services/doctor-service && cp .env.example .env && npm install && npm run dev
cd services/appointment-service && cp .env.example .env && npm install && npm run dev
cd services/frontend && cp .env.example .env && npm install && npm start
```
