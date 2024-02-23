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

  SERVICE_NAMESPACE="$SERVICE_NAME"
  kubectl get namespace "$SERVICE_NAMESPACE" || kubectl create namespace "$SERVICE_NAMESPACE"

  SERVICE_DEPLOYMENT_FILE="$SERVICE_DIR/deployment.yaml"
  kubectl apply -f "$SERVICE_DEPLOYMENT_FILE" --namespace="$SERVICE_NAMESPACE"
}

minikube status || minikube start

# Deploy each service in parallel.
for SERVICE_DIR in $SERVICES
do
  echo "Deploying service: $SERVICE_DIR"
  deploy_service "$SERVICE_DIR" &
done

# Wait for all deployments to finish.
wait

echo ""
echo "To access the service, run the following command:"
echo "minikube service <SERVICE_NAME>-service --url -n <SERVICE_NAME>"
echo ""