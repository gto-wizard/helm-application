#!/bin/bash

set -euo pipefail

HELM_CHART_PATH=${1}
K8S_RESOURCES_DIR=${2}
GTO_ENV=${3:-dev}

# search for all appsets with matching $GTO_ENV directory name
APPSET_FOLDERS="$(find "${K8S_RESOURCES_DIR}/applications/" -maxdepth 2 -type d \( -name "${GTO_ENV}" \)  ! -path "${K8S_RESOURCES_DIR}/applications/infrastructure/*" | sort)"
for APPSET_FOLDER in ${APPSET_FOLDERS}; do
  VALUE_FILES=$(find "${APPSET_FOLDER}" -maxdepth 1 -type f -name "*.yaml" ! -name "*.image.yaml")
  for VALUE_FILE in ${VALUE_FILES}; do
    # Get the file name without extension,
    # ex: ./k8s-resources/applications/application/agg-reports/dev/ai-engine.yaml -> ai-engine
    app_name=$(basename "$VALUE_FILE" ".yaml")
    helm template "${app_name}" --values "${VALUE_FILE}" "${HELM_CHART_PATH}"
  done
done
