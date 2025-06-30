#!/bin/bash
set -e

RELEASE_NAME=ui-test-release
NAMESPACE=helm-ui-test

# Create the namespace if it doesn't exist
kubectl create namespace $NAMESPACE || true

echo "[INFO] Linting Helm chart..."
helm lint ./chart

echo "[INFO] Installing Helm chart..."
helm install $RELEASE_NAME ./chart -n $NAMESPACE --wait

echo "[INFO] Waiting for all pods to be Ready in namespace: $NAMESPACE..."
kubectl wait --for=condition=Ready pods --all -n $NAMESPACE --timeout=180s

# List all resources in the namespace
kubectl get all -n $NAMESPACE

echo "[INFO] Checking frontend service accessibility..."
kubectl port-forward svc/frontend 8080:80 -n $NAMESPACE &
PF_PID=$!

# Wait for the port-forward to be ready
sleep 5

# Send a request to the frontend
if curl -fs http://localhost:8080; then
  echo "[OK] Frontend responded successfully."
else
  echo "[ERROR] Frontend did not respond."
  kill $PF_PID
  exit 1
fi

# Stop the port-forward
kill $PF_PID

# Optional: Uncomment the following lines to clean up resources after test
# echo "[INFO] Uninstalling Helm release..."
# helm uninstall $RELEASE_NAME -n $NAMESPACE
#
# echo "[INFO] Deleting namespace $NAMESPACE..."
# kubectl delete namespace $NAMESPACE

echo "[DONE] Helm chart test completed."

