#!/bin/bash

set -euo pipefail

HELM_CHART_PATH=${1}
K8S_RESOURCES_DIR=${2}
GTO_ENV=${3:-dev}

# search for all $GTO_ENV value files in applications/gto-wizard/ folder:
VALUE_FILES="$(find "${K8S_RESOURCES_DIR}/applications/gto-wizard/" -iname "${GTO_ENV}.yaml" | sort)"

# validate charts
for VALUE_FILE in ${VALUE_FILES}; do
    app_dir=$(dirname "$VALUE_FILE") # Get the directory path, ex: ./k8s-resources/applications/gto-wizard/solver-service/dev.yaml -> ./k8s-resources/applications/gto-wizard/solver-service
    app_name=$(basename "$app_dir") # Get the folder name, ex: ./k8s-resources/applications/gto-wizard/solver-service -> solver-service
    helm template "${app_name}" --values "${VALUE_FILE}" "${HELM_CHART_PATH}"
done
