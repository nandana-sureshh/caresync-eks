# Application Setup Reference

## Environment Variables

### Auth Service
| Variable | Source (EKS) | Value |
|---|---|---|
| PORT | hardcoded in deployment | 4001 |
| NODE_ENV | ConfigMap: caresync-config | production |
| MONGO_URI | ConfigMap: AUTH_MONGO_URI | mongodb://caresync-mongodb:27017/authdb |
| JWT_SECRET | Secret: caresync-secrets | (strong random value) |
| JWT_EXPIRES_IN | ConfigMap | 7d |

### Patient Service
Same as auth + AUTH_SERVICE_URL from ConfigMap. MONGO_URI = patientdb.

### Doctor Service
Same as auth + AUTH_SERVICE_URL. MONGO_URI = doctordb.

### Appointment Service
Same + AUTH_SERVICE_URL + PATIENT_SERVICE_URL + DOCTOR_SERVICE_URL. MONGO_URI = appointmentdb.

### Frontend
REACT_APP_* URLs baked in at Docker build time — not runtime environment.

---

## MongoDB Connection

### Kubernetes DNS (EKS)
```
mongodb://caresync-mongodb:27017/authdb
mongodb://caresync-mongodb:27017/patientdb
mongodb://caresync-mongodb:27017/doctordb
mongodb://caresync-mongodb:27017/appointmentdb
```
Full DNS: `caresync-mongodb.caresync.svc.cluster.local:27017`

### Local (docker-compose)
```
mongodb://mongo:27017/authdb
mongodb://mongo:27017/patientdb
mongodb://mongo:27017/doctordb
mongodb://mongo:27017/appointmentdb
```

---

## Kubernetes Config Delivery

| Variable | Stored In |
|---|---|
| Service URLs, Mongo URIs, NODE_ENV, JWT_EXPIRES_IN | ConfigMap: caresync-config |
| JWT_SECRET | Secret: caresync-secrets |

```bash
kubectl get configmap caresync-config -n caresync -o yaml
kubectl get secret caresync-secrets -n caresync -o yaml
```

---

## Health Endpoints

All backend services expose `/health`:
```bash
curl http://localhost:4001/health   # {"status":"ok","service":"auth-service"}
curl http://localhost:4002/health
curl http://localhost:4003/health
curl http://localhost:4004/health
```

---

## Docker Hub Images

| Service | Image |
|---|---|
| auth | nandana2002/caresync-auth:latest |
| patient | nandana2002/caresync-patient:latest |
| doctor | nandana2002/caresync-doctor:latest |
| appointment | nandana2002/caresync-appointment:latest |
| frontend | nandana2002/caresync-frontend:latest |
