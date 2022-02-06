#!/bin/bash

GITHUB_USER=debu99
GITHUB_TOKEN=ghp_XXXXXXXXXXXXXXXX
GITHUB_REPO=github.com/debu99/ppro.git
GITHUB_REPO_NAME=ppro

K8S_CLUSTER_NAME=minikube
K8S_APP_NAME=nodejs
K8S_ENV_NAME=dev
K8S_CLUSTER_NS=dev
K8S_POD_REPLICAS=1
K8S_APP_DNS='dev-nodejs.minikube.local'
K8S_APP_DNS_IP='192.168.49.2'
HELATHCHECK_URL='/healthz'
FLUX_KUSTOMIZATION_NAME=${K8S_ENV_NAME}-app-${K8S_APP_NAME}

ROOT_PWD=`pwd`

function git_add () {
  filename=$1
  kustomization_name=$2
  git_message=$3
  echo "[INFO] filename=$filename kustomization_name=$kustomization_name git_message=$git_message"
  git add $filename
  pwd
  echo "[INFO] filename=$filename kustomization_name=$kustomization_name git_message=$git_message" >> $ROOT_PWD/$GITHUB_REPO_NAME/github.log
  git add $ROOT_PWD/$GITHUB_REPO_NAME/github.log
  git commit -m "[GITHUB_ACTION] ${git_message}" || true
  git push || true
  sleep 5
  flux reconcile kustomization $kustomization_name --verbose
  sleep 25
}

function check_health () {
  NAMESPACE=$1
  HOST=$2
  HOST_URL=$3
  if [[ -z $4 ]]; then
    HTTP_PROTOCOL=http
    HTTP_PORT=80
  else
    HTTP_PROTOCOL=https
    HTTP_PORT=443
  fi
  echo "[INFO] Starting healthcheck on ${HTTP_PROTOCOL}://$HOST$HOST_URL..."
  HEALTH_OK=0
  SLEEP_TIME=5
  TOTAL_TIME=180
  EXIT_NUM=$(((TOTAL_TIME+(SLEEP_TIME-1))/SLEEP_TIME))
  for (( i=0; i<=EXIT_NUM; i++ )); do
    RANDOM_STR=`date '+%Y%m%d-%H%M%S'`-`openssl rand -hex 4`
    echo "[INFO] RANDOM_STR=$RANDOM_STR"
    if [[ -z $K8S_APP_DNS_IP ]]; then
      cmd='ret=`curl -o /dev/null -s -k -w "%{http_code}\\n" '"'$HTTP_PROTOCOL://$HOST$HOST_URL'"'` && exit $ret'
    else
      cmd='ret=`curl -o /dev/null -s -k -w "%{http_code}\\n" '"'$HTTP_PROTOCOL://$HOST$HOST_URL' --header 'Host: ${HOST}' --resolve ${HOST}:${HTTP_PORT}:${K8S_APP_DNS_IP}"'` && exit $ret'
    fi
    #echo "[DEBUG] cmd=${cmd}"
    kubectl run curl-${RANDOM_STR} -i --tty --rm --restart=Never --namespace ${NAMESPACE} --image="debu99/curl" -- bash -c "${cmd}" || ret=$?
    kubectl delete pod --namespace ${K8S_NAMESPACE} curl-${RANDOM_STR} || true
    if [[ ${ret} -eq 200 ]]; then
          HEALTH_OK=1
          echo "[INFO] $i - curl returns 200 from $1, continue to next step..."
          break
      else
          echo "[INFO] $i - curl returns $((ret+256)) from $1, retrying..."
          sleep $SLEEP_TIME
    fi
  done
  if [[ $HEALTH_OK -eq 1 ]]; then
    echo "[INFO] Done healthcheck......"
  else
    echo "[ERROR] Healthcheck timeout"
    exit 1
  fi
}

function initGit() {
  echo "[INFO] Init for ${GITHUB_REPO}"
  git clone https://$GITHUB_USER:$GITHUB_TOKEN@$GITHUB_REPO
  git config --global user.name "GitOps"
  git config --global user.email "gitops@fluxcd.com"
  cd $GITHUB_REPO_NAME
  git remote -v
  git status
  CURRENT_COMMIT=`git rev-parse HEAD | cut -c1-7`
  echo "[INFO] CURRENT_COMMIT=${CURRENT_COMMIT}"
}

function getSlot() {
  echo "[INFO] Get slot for ${K8S_APP_NAME}"
  cd $ROOT_PWD/$GITHUB_REPO_NAME/fluxcd/${K8S_ENV_NAME}/apps/${K8S_APP_NAME}
  CURRENT_SERVICE_NAME=`yq e '.spec.rules[0].http.paths[0].backend.service.name' ingress.yaml`
  if [[ $CURRENT_SERVICE_NAME == *"blue"* ]]; then
    echo "[INFO] Found blue slot is in-use ..."
    OLD_SERVICE_NAME=blue
    NEW_SERVICE_NAME=green
  else
    echo "[INFO] Found green slot is in-use ..."
    OLD_SERVICE_NAME=green
    NEW_SERVICE_NAME=blue
  fi
  OLD_DNS_NAME=${K8S_ENV_NAME}-${K8S_APP_NAME}-${OLD_SERVICE_NAME}.${K8S_CLUSTER_NS}
  OLD_DEPLOY_NAME=${K8S_ENV_NAME}-${K8S_APP_NAME}-${OLD_SERVICE_NAME}
  NEW_DNS_NAME=${K8S_ENV_NAME}-${K8S_APP_NAME}-${NEW_SERVICE_NAME}.${K8S_CLUSTER_NS}
  NEW_DEPLOY_NAME=${K8S_ENV_NAME}-${K8S_APP_NAME}-${NEW_SERVICE_NAME}
}

function updateStandby() {
  echo "[INFO] Start ${K8S_APP_NAME} ${NEW_SERVICE_NAME}"
  cd $ROOT_PWD/$GITHUB_REPO_NAME/fluxcd/${K8S_ENV_NAME}/apps/${K8S_APP_NAME}/${NEW_SERVICE_NAME}
  OLD_TAG=`yq e '.spec.values.image.tag' helmrelease.yaml`
  echo "[INFO] OLD_TAG=${OLD_TAG} CURRENT_COMMIT=${CURRENT_COMMIT} ..."
  echo "[INFO] K8S_POD_REPLICAS=${K8S_POD_REPLICAS}"
  yq e -i ".spec.values.image.tag = \"${CURRENT_COMMIT}\"" helmrelease.yaml
  yq e -i ".spec.values.image.replicas = \"${K8S_POD_REPLICAS}\"" helmrelease.yaml
  cat helmrelease.yaml
  NEW_TAG=`yq e '.spec.values.image.tag' helmrelease.yaml`
  NEW_DEPLOYMENT=`yq e '.spec.releaseName' helmrelease.yaml`
  NEW_REPLICAS=`yq e '.spec.values.image.replicas' helmrelease.yaml`
  echo "[INFO] NEW_DEPLOYMENT=$NEW_DEPLOYMENT NEW_TAG=$NEW_TAG NEW_REPLICAS=${NEW_REPLICAS}"
  git_add helmrelease.yaml ${FLUX_KUSTOMIZATION_NAME} "Update ${NEW_DEPLOYMENT} image tag to ${NEW_TAG} from ${OLD_TAG}"

  HEALTH_OK=0
  SLEEP_TIME=3
  TOTAL_TIME=90
  EXIT_NUM=$(((TOTAL_TIME+(SLEEP_TIME-1))/SLEEP_TIME))
  for (( i=0; i<=EXIT_NUM; i++ )); do
    POD_NAME=`kubectl get pod -n ${K8S_CLUSTER_NS} | grep Running | grep ${NEW_DEPLOYMENT} | head -n1 | awk '{print $1}'` || true
    IMAGE_TAG=`kubectl get pod ${POD_NAME} -n ${K8S_CLUSTER_NS} -o json | jq -re '.spec.containers[].image' | awk -F':' '{print $NF}'` || true
    if [[ ${NEW_TAG} == ${IMAGE_TAG} ]]; then
      echo "[INFO] $i - NEW_TAG=${NEW_TAG} POD_NAME=${POD_NAME} IMAGE_TAG=${IMAGE_TAG}, continue to next step..."
      HEALTH_OK=1
      break
    else
      echo "[INFO] $i - NEW_TAG=${NEW_TAG} POD_NAME=${POD_NAME} IMAGE_TAG=${IMAGE_TAG}, retrying..."
      sleep $SLEEP_TIME
    fi
  done
  kubectl get pod -n ${K8S_CLUSTER_NS} | grep ${NEW_DEPLOYMENT}
  if [[ $HEALTH_OK -ne 1 ]]; then
    echo "[ERROR] Timeout: NEW_TAG=${NEW_TAG} POD_NAME=${POD_NAME} IMAGE_TAG=${IMAGE_TAG}"
    exit 1
  fi
  check_health "${K8S_CLUSTER_NS}" "${NEW_DNS_NAME}" ${HELATHCHECK_URL}
}


function updateIngress() {
  echo "[INFO] Update ingress traffic to ${NEW_DEPLOYMENT}"
  cd $ROOT_PWD/$GITHUB_REPO_NAME/fluxcd/${K8S_ENV_NAME}/apps/${K8S_APP_NAME}/
  yq e -i '.spec.rules[0].http.paths[0].backend.service.name  = "'"${NEW_DEPLOYMENT}"'"' ingress.yaml
  BACKEND_NAME=`yq e '.spec.rules[0].http.paths[0].backend.service.name' ingress.yaml`
  if [[ $BACKEND_NAME != ${NEW_DEPLOYMENT} ]]; then
    echo "[ERROR] NEW_DEPLOYMENT=${NEW_DEPLOYMENT} BACKEND_NAME=${BACKEND_NAME}"
    exit 1
  else
    echo "[INFO] Ingress updated to ${NEW_DEPLOYMENT} ..."
  fi
  git_add ingress.yaml ${FLUX_KUSTOMIZATION_NAME} "Update ingress with backend service name ${BACKEND_NAME}"
  check_health ${K8S_CLUSTER_NS} ${K8S_APP_DNS} ${HELATHCHECK_URL}
}

function downScale() {
  echo "[INFO] Down scale ${OLD_SERVICE_NAME} to 0"
  cd $ROOT_PWD/$GITHUB_REPO_NAME/fluxcd/${K8S_ENV_NAME}/apps/${K8S_APP_NAME}/${OLD_SERVICE_NAME}
  CURRENT_NUM=`yq e '.spec.values.image.replicas' helmrelease.yaml`
  if [[ ! -z $CURRENT_NUM ]] && [[ $CURRENT_NUM -eq 0 ]]; then
      echo "[INFO] CURRENT_NUM = 0, skipping..."
  else
      echo "[INFO] CURRENT_NUM=${CURRENT_NUM}"
      yq e -i '.spec.values.image.replicas = 0' helmrelease.yaml
      git_add helmrelease.yaml ${FLUX_KUSTOMIZATION_NAME} "Scale down ${OLD_DEPLOY_NAME} to 0"
      HEALTH_OK=0
      SLEEP_TIME=3
      TOTAL_TIME=90
      EXIT_NUM=$(((TOTAL_TIME+(SLEEP_TIME-1))/SLEEP_TIME))
      for (( i=0; i<=EXIT_NUM; i++ )); do
        OLD_POD_NUM=`kubectl get pod -n ${K8S_CLUSTER_NS}  | grep ${OLD_DEPLOY_NAME} | wc -l`
        if [[ ${OLD_POD_NUM} -eq 0 ]]; then
          echo "[INFO] $i - OLD_DEPLOY_NAME=${OLD_DEPLOY_NAME} OLD_POD_NUM=${OLD_POD_NUM}, continue to next step..."
          HEALTH_OK=1
          break
        else
          echo "[INFO] $i - OLD_DEPLOY_NAME=${OLD_DEPLOY_NAME} OLD_POD_NUM=${OLD_POD_NUM}, retrying..."
          sleep $SLEEP_TIME
        fi
      done
      if [[ $HEALTH_OK -ne 1 ]]; then
        echo "[ERROR] Timeout: OLD_DEPLOY_NAME=${OLD_DEPLOY_NAME} OLD_POD_NUM=${OLD_POD_NUM}"
        exit 1
      fi
      check_health ${K8S_CLUSTER_NS} "${K8S_APP_DNS}" ${HELATHCHECK_URL}
  fi
}

initGit
getSlot
updateStandby
updateIngress
downScale



