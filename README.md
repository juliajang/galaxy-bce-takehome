# galaxy-bce (Flask app)

This repository contains a minimal Flask app (`app.py`), a multi-stage `Dockerfile` and Kubernetes manifests in `k8s/` to run the service in a cluster.

**What the repo provides**
- `app.py` — Flask app with `/` (root) and `/dummy` endpoints.
- `Dockerfile` — multi-stage build producing a small runtime image that runs `gunicorn` on port `8080` as a non-root user.
- `k8s/` — production-oriented manifests: `namespace.yaml`, `deployment.yaml`, `service.yaml`, `ingress.yaml`, `hpa.yaml`, `pdb.yaml`, and `limitrange.yaml`.

**Local development**
- Run with the Flask dev server (binds to `0.0.0.0:5000` in this repo):
```bash
python3 -m pip install -r requirements.txt
python3 app.py
curl http://127.0.0.1:5000/
```
- Run using `gunicorn` (same runtime as the container):
```bash
python3 -m pip install -r requirements.txt
gunicorn --workers 3 --bind 0.0.0.0:8080 app:app
curl http://127.0.0.1:8080/
```

**Build the container**
- Local image tag used in the Kubernetes deployment (convenient for `kind`/local clusters):
```bash
docker build -t galaxy-bce:local .
```
- Push to a registry (recommended for cloud clusters):
```bash
docker build -t registry.example.com/<org>/galaxy-bce:1.0.0 .
docker push registry.example.com/<org>/galaxy-bce:1.0.0
```

If you use a local Kubernetes (kind/minikube):
- kind: `kind load docker-image galaxy-bce:local --name <cluster-name>`
- minikube: `minikube image load galaxy-bce:local`

**Kubernetes deployment (apply order)**
1. Create the Namespace first (the rest are namespaced resources):
```bash
kubectl apply -f k8s/namespace.yaml
```
2. Apply the rest (namespace must exist first):
```bash
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/pdb.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/ingress.yaml
```

Notes about the manifests
- The `Deployment` in `k8s/deployment.yaml` is configured to use the image `galaxy-bce:local` with `imagePullPolicy: IfNotPresent` (convenient for local clusters). Update `image` to your registry tag when deploying to remote clusters.
- Liveness/readiness probes are configured to use `/health` and `/ready` respectively. Ensure those endpoints exist or adjust the paths.
- `Service` is `ClusterIP` exposing port `80` to pods' port `8080`. `Ingress` routes `galaxy-bce.example.com` and `galaxy-bce.example.com/dummy` to the service.
- `HPA` is configured (minReplicas: 1, maxReplicas: 10) and targets CPU utilization — ensure `metrics-server` is installed in your cluster for HPA to work.

**Quick test from your workstation**
- Port-forward the service and curl locally:
```bash
kubectl -n galaxy-bce-prod port-forward svc/galaxy-bce-svc 8080:80
curl http://127.0.0.1:8080/
curl http://127.0.0.1:8080/dummy
```

**Run the container locally (matches Dockerfile runtime)**
- Container uses port `8080`. Run locally:
```bash
docker run --rm -p 8080:8080 galaxy-bce:local
curl http://127.0.0.1:8080/
```

**Troubleshooting tips**
- If you see `ImagePullBackOff` for image `galaxy-bce:local`, load the image into your cluster (`kind load docker-image` or `minikube image load`) or push the image to a registry accessible by cluster nodes and update `k8s/deployment.yaml`.
- If server-side `kubectl --dry-run=server` validation fails for namespaced resources, create the namespace first:
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/ --dry-run=server
```
