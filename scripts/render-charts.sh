#!/bin/bash

set -euo pipefail

HELM_CHART_PATH=${1}
K8S_RESOURCES_DIR=${2}
GTO_ENV=${3:-dev}

# search for all $GTO_ENV value files in applications/gto-wizard/ folder:
VALUE_FILES="$(find "${K8S_RESOURCES_DIR}/applications/gto-wizard/" -iname "${GTO_ENV}.yaml" | sort)"

for VALUE_FILE in ${VALUE_FILES}; do
    app_dir=$(dirname "$VALUE_FILE") # Get the directory path, ex: ./k8s-resources/applications/gto-wizard/solver-service/dev.yaml -> ./k8s-resources/applications/gto-wizard/solver-service
    app_name=$(basename "$app_dir") # Get the folder name, ex: ./k8s-resources/applications/gto-wizard/solver-service -> solver-service
    helm template "${app_name}" --values "${VALUE_FILE}" "${HELM_CHART_PATH}"
done

# search for all apps with matching env name
APPSET_FOLDERS="$(find "${K8S_RESOURCES_DIR}/applications/" -maxdepth 2 -type d \( -name "${GTO_ENV}" \)  ! -path "*/infrastructure/*" | sort)"

for APPSET_FOLDER in ${APPSET_FOLDERS}; do
  VALUE_FILES=$(find "${APPSET_FOLDER}" -maxdepth 1 -type f -name "*.yaml" ! -name "*.image.yaml")
  for VALUE_FILE in ${VALUE_FILES}; do
    # Get the file name without extension,
    # ex: ./k8s-resources/applications/application/agg-reports/dev/ai-engine.yaml -> ai-engine
    app_name=$(basename "$VALUE_FILE" ".yaml")
    helm template "${app_name}" --values "${VALUE_FILE}" "${HELM_CHART_PATH}"
  done
done
