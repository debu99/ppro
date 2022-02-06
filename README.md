## Description

This repo is a demo of how to use drone CI and flux CD for a Nodejs app release

## Folder Structure

```
/
│   README.md
│   .drone.yaml
└───nodejs
    └───Dockerfile
    └───app.js
    └───dbs
        └───index.js
    └───routes
        └───index.js
    └───package.json
    └───package-lock.json
└───charts
    └───nodejs
        └───templates
        └───Chart.yaml
        └───values.yaml
└───fluxcd
    └───clusters/minikube
        └───fluxcd
            └───flux-system
            └───infra-common.yaml
            └───infra-components.yaml
            └───dev-app-nodejs.yaml
            └───prod-app-nodejs.yaml
        └───infra/common/kustomization.yaml
        └───infra/components/kustomization.yaml
        └───dev/apps/nodejs/kustomization.yaml
        └───prod/apps/nodejs/kustomization.yaml
    └───infra
        └───common
            └───0.namespaces.yaml
            └───1.helmrepository.yaml
            └───2.helmrelease.yaml 
            └───kustomization.yaml
        └───components
            └───drone-runner-kube
            └───drone
            └───external-secrets-crd
            └───mongodb
            └───registry
    └───dev/apps/nodejs
        └───blue
        └───green
        └───ingress.yaml
        └───kustomization.yaml
    └───prod/apps/nodejs
        └───blue
        └───green
        └───ingress.yaml
        └───kustomization.yaml

```

| File/Folder | Usage |
| ------ | ------ |
| [README.md](./README.md) | This file |
| [.drone.yaml](./.drone.yaml) | Drone CI pipeline to build the docker image |
| [nodejs/Dockerfile](./nodejs/Dockerfile) | Dockerfile for nodejs app |
| [nodejs/app.js](./nodejs/app.js) | Main function for nodejs app |
| [nodejs/package.json](./nodejs/package.json) | Package info for nodejs app |
| [charts/nodejs/templates](./charts/nodejs/templates) | Templates for nodejs app |
| [charts/nodejs/Chart.yaml](./charts/nodejs/Chart.yaml) | Manifest file for nodejs chart |
| [charts/nodejs/values.yaml](./charts/nodejs/values.yaml) | Default chart values for nodejs app |
| [fluxcd/clusters/minikube/fluxcd/flux-system](./fluxcd/clusters/minikube/fluxcd/flux-system) | FluxCD configuration for cluster minikube |
| [fluxcd/clusters/minikube/fluxcd/infra-common.yaml](./fluxcd/clusters/minikube/fluxcd/infra-common.yaml) | Dependent infra components for the K8s clusters that needs to deploy first |
| [fluxcd/clusters/minikube/fluxcd/infra-components.yaml](./fluxcd/clusters/minikube/fluxcd/infra-components.yaml) | General infra components for all the K8s clusters |
| [fluxcd/clusters/minikube/fluxcd/dev-app-nodejs.yaml](./fluxcd/clusters/minikube/fluxcd/dev-app-nodejs.yaml) | Nodejs app for dev environment |
| [fluxcd/clusters/minikube/fluxcd/prod-app-nodejs.yaml](./fluxcd/clusters/minikube/fluxcd/prod-app-nodejs.yaml) | Nodejs app for prod environment |
| [fluxcd/clusters/minikube/infra/common/kustomization.yaml](./fluxcd/clusters/minikube/infra/common/kustomization.yaml) | Kustomization file for infra component depencecies |
| [fluxcd/clusters/minikube/infra/components/kustomization.yaml](./fluxcd/clusters/minikube/infra/components/kustomization.yaml) | Kustomization file for infra components |
| [fluxcd/clusters/minikube/dev/apps/nodejs/kustomization.yaml](./fluxcd/clusters/minikube/dev/apps/nodejs/kustomization.yaml) | Kustomization file for dev nodejs app |
| [fluxcd/clusters/minikube/prod/apps/nodejs/kustomization.yaml](./fluxcd/clusters/minikube/prod/apps/nodejs/kustomization.yaml) | Kustomization file for prod nodejs app |
| [fluxcd/infra/common/0.namespaces.yaml](./fluxcd/infra/common/0.namespaces.yaml) | Create namespaces for K8s cluster |
| [fluxcd/infra/common/1.helmrepository.yaml](./fluxcd/infra/common/1.helmrepository.yaml) | Add helm repos for K8s cluster |
| [fluxcd/infra/common/2.helmrelease.yaml](./fluxcd/infra/common/2.helmrelease.yaml) | Helm install externalsecrets dependency for K8s cluster |
| [fluxcd/infra/common/kustomization.yaml](./fluxcd/infra/common/kustomization.yaml) | Kustomization file for infra common |
| [fluxcd/infra/components/external-secrets-crd](./fluxcd/infra/components/external-secrets-crd) | Externalsecret CRD to initialize secrets from Vault  |
| [fluxcd/infra/components/drone](./fluxcd/infra/components/drone) | Drone CI |
| [fluxcd/infra/components/drone-runner-kube](./fluxcd/infra/components/drone-runner-kube) | Drone CI runner |
| [fluxcd/infra/components/registry](./fluxcd/infra/components/registry) | Private docker registry |
| [fluxcd/infra/components/mongodb](./fluxcd/infra/components/mongodb) | MongoDB database for nodejs app  |
| [fluxcd/dev/apps/nodejs/blue](./fluxcd/dev/apps/nodejs/blue) | Nodejs app blue release template  |
| [fluxcd/dev/apps/nodejs/green](./fluxcd/dev/apps/nodejs/green) | Nodejs app green release template  |
| [fluxcd/dev/apps/nodejs/ingress.yaml](./fluxcd/dev/apps/nodejs/ingress.yaml) | Ingress for nodejs app  |
| [fluxcd/dev/apps/nodejs/kustomization.yaml](./fluxcd/dev/apps/nodejs/kustomization.yaml) | Kustomization installation file for nodejs app |
| [fluxcd/prod/apps/nodejs/blue](./fluxcd/prod/apps/nodejs/blue) | Nodejs app blue release template  |
| [fluxcd/prod/apps/nodejs/green](./fluxcd/prod/apps/nodejs/green) | Nodejs app green release template  |
| [fluxcd/prod/apps/nodejs/ingress.yaml](./fluxcd/prod/apps/nodejs/ingress.yaml) | Ingress for nodejs app  |
| [fluxcd/prod/apps/nodejs/kustomization.yaml](./fluxcd/prod/apps/nodejs/kustomization.yaml) | Kustomization installation file for nodejs app |

## Requirements
| Name | Version |
|------|---------|
| [Docker](https://www.docker.com) | >= 20.10.12 |
| [Helm](https://helm.sh) | >= 3.7.2 |
| [Minikube](https://minikube.sigs.k8s.io) | >= 1.25.1 |
| [Kubernetes](https://kubernetes.io) | >= 1.23.1 |
| [Vault](https://www.vaultproject.io) | >= 1.5.9 |
| [FluxCD](https://fluxcd.io) | >= 0.26.1 |

## Prerequisite
- Allow insecure docker registry
```
vi /etc/docker/daemon.json
{
  "insecure-registries" : ["docker-registry.registry:32080"]
}

# Restart docker daemon
systemctl restart docker
```
- Start minikube 
```
# Create directories to mount into minikube cluster
sudo mkdir -p /volume/{registry,drone}
sudo chown -R 1000:root /volume/

# Start minikube with docker driver
minikube start --driver=docker --insecure-registry=192.168.49.0/24 --mount-string="/volume:/volume" --mount=true
minikube status

# Enable ingress for app access
minikube addons enable ingress
```
- Add private docker registry dns into local hosts file
```
echo "`minikube ip` docker-registry.registry" | sudo tee -a /etc/hosts
minikube ssh "echo '`minikube ip` docker-registry.registry' | sudo tee -a /etc/hosts"
```
- Start vault as external secrets storage
```
# Start Vault as docker
docker run -d --cap-add=IPC_LOCK --network=host -e VAULT_DEV_ROOT_TOKEN_ID=root -e VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200 -e VAULT_ADDR='http://0.0.0.0:8200' -e 'VAULT_LOCAL_CONFIG={"backend": {"file": {"path": "/vault/file"}}, "default_lease_ttl": "168h", "max_lease_ttl": "720h"}' vault server -dev
export VAULT_ADDR=http://0.0.0.0:8200

# Init app related credentials
vault kv put secret/testapp/config username='root' password='example' host='mongodb.db'
vault kv get secret/testapp/config

# Init MongoDB related credentials
vault kv put secret/mongodb/config mongodb_root_password='example'
vault kv get secret/mongodb/config

# Init Drone related credentials
vault kv put secret/drone/config github_id='45fxxxxxxxxxxxxxx' github_secret='beaf624743c9646exxxxxxxxxxxxxxxxxxxxx' rpc_secret='rpc-secret'
vault kv get secret/drone/config

# Create Vault access policy
vault policy write external-secrets - <<EOF
path "secret/data/testapp/config" {
  capabilities = ["list", "read"]
}
path "secret/data/drone/config" {
  capabilities = ["list", "read"]
}
path "secret/data/mongodb/config" {
  capabilities = ["list", "read"]
}
EOF
vault policy read external-secrets

# Enable Vault K8s authentication for external secrets token
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')
EXTERNAL_SECRETS_TOKEN_NAME=$(kubectl get secrets --output=json -n infra| jq -r '.items[].metadata | select(.name|startswith("external-secrets-token-")).name')
TOKEN_REVIEW_JWT=$(kubectl get secret $EXTERNAL_SECRETS_TOKEN_NAME -n infra --output='go-template={{ .data.token }}' | base64 --decode)

vault auth enable kubernetes
vault write auth/kubernetes/config token_reviewer_jwt="$TOKEN_REVIEW_JWT" kubernetes_host="$KUBE_HOST" kubernetes_ca_cert="$KUBE_CA_CERT" issuer="https://kubernetes.default.svc.cluster.local"
vault read auth/kubernetes/config

# Create Vault role and bind to external secrets service account
vault write auth/kubernetes/role/external-secrets bound_service_account_names=external-secrets bound_service_account_namespaces='infra' policies=external-secrets ttl=1h

```

- Init FluxCD
```
export GITHUB_USER=debu99
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxx

# Install flux into minikube and use this repo as source
flux bootstrap github --owner=${GITHUB_USER} --repository=ppro --path=fluxcd/clusters/minikube/fluxcd --personal
flux get all
flux reconcile kustomization flux-system
```

## GitOps flow
- DroneCI: 
Drone pipeline will build docker image from [nodejs folder](./nodejs) and tag with current commit id, then push to http://docker-registry.registry:32080/nodejs private docker registry repo in the local.

- FluxCD(blue/green deployment):
  1. Check current ingress backend service name color, increase the standby color pod replica to 1 and use the latest commit id tag for image, commit the changes to this repo
  2. Reconcile the state with FluxCD, once the standby color pod is running, test its service with healthcheck url.
  3. Update app ingress backend to the standby color service and then commit the changes to this repo, after that do another round of healthcheck on the real domain name to make sure the traffic has been switched successfully.
  4. Scale down the previous color deployment replica to zero and commit the changes to this repo

## How to test app access
```
# For dev environment
kubectl get pod,ingress -n dev
DNS_NAME='dev-nodejs.minikube.local'
curl -i --header "Host: ${DNS_NAME}" http://`minikube ip`

# For prod environment
DNS_NAME='prod-nodejs.minikube.local'
curl -i --header "Host: ${DNS_NAME}" http://`minikube ip`
```
---
