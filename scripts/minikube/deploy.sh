#!/bin/sh
# This script deploys services in a monorepo 
# to a Kubernetes cluster using Minikube.
set -e

if ! command -v minikube >/dev/null 2>&1
then
    echo "Minikube is not installed. Please install Minikube and try again."
    echo "https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

CURRENT_SCRIPT_DIR=$(dirname "$0")
PROJECT_ROOT_DIR=$(realpath "$CURRENT_SCRIPT_DIR/../..")
SERVICES_ROOT_DIR="$PROJECT_ROOT_DIR/services"

# If command line arguments are provided, deploy only the specified services.
# Otherwise, deploy all services found in the services directory.
if [ -n "$1" ]; then
  SERVICES=$*
else
  SERVICES=$(find "$SERVICES_ROOT_DIR" -type f -name deployment.yaml -print0 | xargs -0 -n1 dirname)
fi

PROJECT_NAME=$(node -e "console.log(require('$PROJECT_ROOT_DIR/package.json').name)")
SERVICE_NAMESPACE="$PROJECT_NAME"

deploy_service() {
  SERVICE_DIR="$1"
  SERVICE_DIR=$(echo "$SERVICE_DIR" | sed 's:/*$::')

  if [ ! -d "$SERVICE_DIR" ]; then
    echo "ERROR: Service directory not found '$SERVICE_DIR'"
    exit 1
  fi

  SERVICE_NAME=$(basename "$SERVICE_DIR")

  SERVICE_DOCKER_FILE="$SERVICE_DIR/Dockerfile"
  if [ ! -f "$SERVICE_DOCKER_FILE" ]; then
    echo "ERROR: Dockerfile not found '$SERVICE_DOCKER_FILE'"
    exit 1
  fi

  SERVICE_DOCKER_IMAGE="$SERVICE_NAME"
  docker build -t "$SERVICE_DOCKER_IMAGE" -f "$SERVICE_DOCKER_FILE" .

  minikube image load "$SERVICE_DOCKER_IMAGE"

  SERVICE_DEPLOYMENT_FILE="$SERVICE_DIR/deployment.yaml"
  kubectl delete -f "$SERVICE_DEPLOYMENT_FILE" --namespace="$SERVICE_NAMESPACE" 2>/dev/null || true
  kubectl apply -f "$SERVICE_DEPLOYMENT_FILE" --namespace="$SERVICE_NAMESPACE"
}

minikube status || minikube start
kubectl get namespace "$SERVICE_NAMESPACE" 2>/dev/null || kubectl create namespace "$SERVICE_NAMESPACE"

# Deploy each service in parallel.
for SERVICE_DIR in $SERVICES
do
  echo "Deploying service: $SERVICE_DIR"
  deploy_service "$SERVICE_DIR" &
done

# Wait for all deployments to finish.
wait

SERVICES_EXTERNAL=""
for SERVICE_DIR in $SERVICES
do
  SERVICE_NAME=$(basename "$SERVICE_DIR")
  SERVICE_EXTERNAL_PORT=${SERVICE_EXTERNAL_PORT:-3000}
  SERVICE_EXTERNAL_PORT=$((SERVICE_EXTERNAL_PORT+1))
  SERVICES_EXTERNAL="$SERVICES_EXTERNAL $SERVICE_NAME:$SERVICE_EXTERNAL_PORT"
done

cat <<EOF | kubectl apply --namespace="$SERVICE_NAMESPACE" -f -
apiVersion: v1
kind: Service
metadata:
  name: external-loadbalancer
spec:
  type: LoadBalancer
  ports:
$(for SERVICE in $SERVICES_EXTERNAL; do
  SERVICE_NAME=$(echo "$SERVICE" | cut -d: -f1)
  SERVICE_EXTERNAL_PORT=$(echo "$SERVICE" | cut -d: -f2)
  echo "  - name: $SERVICE_NAME"
  echo "    port:  $SERVICE_EXTERNAL_PORT"
  echo "    targetPort: $SERVICE_NAME-port"
done)
  selector:
    loadbalancer-type: external
EOF

echo ""
echo "Services:"
for SERVICE in $SERVICES_EXTERNAL
do
  SERVICE_NAME=$(echo "$SERVICE" | cut -d: -f1)
  SERVICE_EXTERNAL_PORT=$(echo "$SERVICE" | cut -d: -f2)
  echo "  $SERVICE_NAME: http://127.0.0.1:$SERVICE_EXTERNAL_PORT"
done
echo ""
echo "To access the services, run command:"
echo "  minikube tunnel"