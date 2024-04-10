# npm monorepo template

This is a template for a monorepo using NPM workspaces, Docker and TypeScript. This describes how to build, develop, deploy and test the nodejs services

## 🏗️ Build

Before building the project, you need to install the dependencies. You can do this by running the following command:

```bash
npm ci
```

To build specific packages, you can use the following command:

```bash
npm run build -w <package-name>
```

If you want to build all packages, you can use the following command:

```bash
npm run build --workspaces --if-present
```

## 🖥️ Development

To run the service, you can use the following command:

```bash
npm run dev -w <package-name>
```

If you want to rebuild a service when a service's files change,
you can use the following after running the `dev` command:

```bash
npm run build --watch -w <package-name>
```

## 🚀 Deployment

### 🐳 Docker

To deploy the service, you can use the following command:

```bash
docker compose up foo1 --force-recreate --build
```

To stop the service, you can use the following command:

```bash
docker compose down
```

### ☸️ Kubernetes

To deploy all services, you can use the following command:

```bash
./scripts/minikube/deploy.sh
```

To deploy specific services, you can use the following command:

```bash
./scripts/minikube/deploy.sh <service-name> <service-name> ...
```

## 🧪 Test

To run the all tests, you can use the following command:

```bash
npm run test:all -w <package-name>
```
