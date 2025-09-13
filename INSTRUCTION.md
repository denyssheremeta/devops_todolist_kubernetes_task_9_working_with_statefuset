# INSTRUCTION.md

# Create the kind cluster:

```
kind create cluster --config cluster.yml
```

# Run the bootstrap script:

```
chmod +x bootstrap.sh
./bootstrap.sh
```

# Check MySQL StatefulSet:

```
kubectl get pods -n mysql
kubectl get svc -n mysql
```

# You should see pods mysql-0, mysql-1, mysql-2 in Running/Ready state and a headless Service mysql with clusterIP: None.

Check the application namespace and secret:

```
kubectl get ns todoapp
kubectl get secret app-db-secret -n todoapp -o yaml
```

# The secret app-db-secret must contain keys NAME, USER, PASSWORD, HOST. The HOST value must point to mysql-0.mysql.mysql.svc.cluster.local.

Verify that the Deployment consumes the correct keys:

```
kubectl get deployment todoapp -n todoapp -o yaml | grep -A2 "env:"
```

# Check the PVC:

```
kubectl get pvc -n todoapp
kubectl describe pvc pvc-data -n todoapp
```

# The status must be Bound. If volumeName: pv-data is set, ensure that a PV named pv-data exists and is available.

Verify that the application is deployed:

```
kubectl rollout status deployment/todoapp -n todoapp --timeout=180s
kubectl get pods -n todoapp -o wide
kubectl get svc -n todoapp
```

# Test the application health endpoints:

```
kubectl port-forward -n todoapp deploy/todoapp 8080:8080
In another terminal:
curl -f http://localhost:8080/api/health
curl -f http://localhost:8080/api/ready
```

# Check DNS resolution from the application pod to mysql-0:

```
POD=$(kubectl get pods -n todoapp -l app=todoapp -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n todoapp $POD -- getent hosts mysql-0.mysql.mysql.svc.cluster.local
```

# If all checks pass successfully, the setup is valid.
