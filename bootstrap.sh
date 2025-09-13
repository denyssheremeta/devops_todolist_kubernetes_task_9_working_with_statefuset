#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo ">>> Creating kind cluster (if not exists)..."
if ! kind get clusters | grep -q "^todo-cluster$"; then
  kind create cluster --config cluster.yml
else
  echo "kind cluster 'todo-cluster' already exists"
fi

echo ">>> Applying MySQL namespace, secret, configmap, service, statefulset..."
kubectl apply -f ./.infrastructure/statefulSet.yml

echo ">>> Waiting for MySQL StatefulSet to be ready (3 replicas)..."
kubectl rollout status statefulset/mysql -n mysql --timeout=180s

echo ">>> Applying app namespace + DB secret + PVC..."
kubectl apply -f ./.infrastructure/app-db-secret.yml
kubectl apply -f ./.infrastructure/app-pvc.yml

echo ">>> Applying app config/secret if present (ignore if missing)..."
kubectl apply -f ./.infrastructure/app-config.yml || true
kubectl apply -f ./.infrastructure/app-secret.yml || true

echo ">>> Applying app Deployment/Service..."
kubectl apply -f ./.infrastructure/deployment.yml
kubectl apply -f ./.infrastructure/service.yml || true

echo ">>> Waiting for app Deployment to be ready..."
kubectl rollout status deployment/todoapp -n todoapp --timeout=180s

echo ">>> Summary:"
kubectl get pods -n mysql -o wide
kubectl get pods -n todoapp -o wide
kubectl get svc -n mysql
kubectl get svc -n todoapp