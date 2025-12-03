# galaxy-bce (Flask app)

This repository contains a minimal Flask app (`app.py`) and a `Dockerfile` to run it in a container.

Build the Docker image:

```bash
docker build -t galaxy-bce .
```

## Build and deploy (example)

Build the container locally, tag and push to your registry. Replace `registry.example.com/<org>` with your repo.

```bash
# build
docker build -t registry.example.com/<org>/galaxy-bce:1.0.0 .

# push (example for dockerhub/other registries)
docker push registry.example.com/<org>/galaxy-bce:1.0.0
```

Apply Kubernetes manifests (they assume you have access to the target cluster):

```bash
# create namespace and basic objects
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/limitrange.yaml
kubectl apply -f k8s/serviceaccount.yaml

# deploy app and related resources
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/pdb.yaml
kubectl apply -f k8s/ingress.yaml
```

Notes:
- The manifests use `registry.example.com/galaxy-bce:latest` as the image — update the `image` in `k8s/deployment.yaml` to match your registry tag.
- The Ingress host is set to `galaxy-bce.example.com` (dummy URL). Add a DNS A/CNAME record pointing to your ingress controller's external IP.
- TLS is commented in `k8s/ingress.yaml`; if using `cert-manager` enable the annotation and TLS stanza.

Run the container (maps container port 5000 to host port 5000):

```bash
docker run --rm -p 5000:5000 galaxy-bce
```

Then open `http://localhost:5000` to see the app.
