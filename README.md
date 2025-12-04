# galaxy-bce (Flask app)

This repository contains a minimal Flask app (`app.py`), a multi-stage `Dockerfile`, and **production-ready Kubernetes manifests** in both raw YAML (`k8s/`) and **Helm chart** (`helm/`) formats.

**What the repo provides**
- `app.py` — Flask app with `/` (root) and `/dummy` endpoints.
- `Dockerfile` — multi-stage build producing a small runtime image that runs `gunicorn` on port `5000` as a non-root user.
- `k8s/` — raw Kubernetes manifests: `namespace.yaml`, `deployment.yaml`, `service.yaml`, `ingress.yaml`, `hpa.yaml`, `pdb.yaml`, and `limitrange.yaml`.
- `helm/` — **production-grade Helm chart** for templating, packaging, and reusing manifests across multiple similar applications.

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
gunicorn --workers 3 --bind 0.0.0.0:5000 app:app
curl http://127.0.0.1:5000/
```

**Build the container**
- Local image tag used in the Kubernetes deployment (convenient for `kind`/local clusters):
```bash
docker build -t galaxy-bce:latest .
```
- Push to a registry (recommended for cloud clusters):
```bash
docker build -t registry.example.com/<org>/galaxy-bce:1.0.0 .
docker push registry.example.com/<org>/galaxy-bce:1.0.0
```

If you use a local Kubernetes (kind/minikube):
- kind: `kind load docker-image galaxy-bce:latest --name <cluster-name>`
- minikube: `minikube image load galaxy-bce:latest`

**Kubernetes deployment (apply order) — Raw YAML**
*Kubernetes manifests were included for reference*
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

**Kubernetes deployment — Helm Chart (Recommended)**

Helm provides templating, reusability, and easier management of Kubernetes manifests. This is recommended for production deployments and deploying the same app across multiple namespaces or clusters.

*Prerequisites:*
- `helm` CLI installed (see [helm.sh](https://helm.sh/docs/intro/install/))

*Deploy using Helm:*
```bash
# Lint the chart to validate syntax
helm lint ./helm

# Template (dry-run) to see what will be deployed
helm template galaxy-bce ./helm

# Install the release
helm install galaxy-bce ./helm -n galaxy-bce-dev --create-namespace

# Verify the installation
helm status galaxy-bce -n galaxy-bce-dev
kubectl get all -n galaxy-bce-dev
```

*Upgrade the release (after making changes):*
```bash
helm upgrade galaxy-bce ./helm -n galaxy-bce-dev
```

*Uninstall the release:*
```bash
helm uninstall galaxy-bce -n galaxy-bce-dev
```

*Customize deployment via values file:*

Create a custom `values.yaml` file.

Deploy with custom values:
```bash
helm install galaxy-bce ./helm -n galaxy-bce-prod --create-namespace -f values-prod.yaml
```

Or use `--set` for quick overrides:
```bash
helm install galaxy-bce ./helm \
  -n galaxy-bce-prod \
  --create-namespace \
  --set image.tag=v1.2.0 \
  --set replicaCount=5 \
  --set ingress.host=galaxy-bce-prod.example.com
```

Notes about the manifests
- The `Deployment` in `k8s/deployment.yaml` is configured to use the image `galaxy-bce:latest` with `imagePullPolicy: IfNotPresent` (convenient for local clusters). Update `image` to your registry tag when deploying to remote clusters.
- Liveness/readiness probes are configured to use `/health` and `/ready` respectively. Ensure those endpoints exist or adjust the paths.
- `Service` is `ClusterIP` exposing port `80` to pods' port `5000`. `Ingress` routes `galaxy-bce-{env}.example.com` and `galaxy-bce-{env}.example.com/dummy` to the service.
- `HPA` is configured (minReplicas: 1, maxReplicas: 10) and targets CPU utilization — ensure `metrics-server` is installed in your cluster for HPA to work.

**Quick test from your workstation**
- Port-forward the service and curl locally:
```bash
kubectl -n galaxy-bce-prod port-forward svc/galaxy-bce-svc 8080:80
curl http://127.0.0.1:8080/
curl http://127.0.0.1:8080/dummy
```

**Run the container locally (matches Dockerfile runtime)**
- Container uses port `5000`. Run locally:
```bash
docker run --rm -p 8080:5000 galaxy-bce:latest
curl http://127.0.0.1:8080/
```

**Troubleshooting tips**
- If you see `ImagePullBackOff` for image `galaxy-bce:latest`, load the image into your cluster (`kind load docker-image` or `minikube image load`) or push the image to a registry accessible by cluster nodes and update `k8s/deployment.yaml`.
- If server-side `kubectl --dry-run=server` validation fails for namespaced resources, create the namespace first:
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/ --dry-run=server
```
