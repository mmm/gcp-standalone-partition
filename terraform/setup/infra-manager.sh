#!/bin/bash

LOCATION="us-central1"
DEPLOYMENT_ID="setup"
SERVICE_ACCOUNT_PROJECT_ID="${GOOGLE_CLOUD_PROJECT}"
SERVICE_ACCOUNT_EMAIL="config-agent@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com"
GIT_REPO="https://github.com/mmm/gcp-standalone-partition"
DIRECTORY="terraform/setup"
INPUTS=project_id=${GOOGLE_CLOUD_PROJECT}

gcloud alpha infra-manager deployments apply \
  "projects/${GOOGLE_CLOUD_PROJECT}/locations/${LOCATION}/deployments/${DEPLOYMENT_ID}" \
  --service-account "projects/${SERVICE_ACCOUNT_PROJECT_ID}/serviceAccounts/${SERVICE_ACCOUNT_EMAIL}" \
  --git-source-repo="${GIT_REPO}" \
  --git-source-directory="${DIRECTORY}" \
  --input-values="${INPUTS}"

  #--input-values="${INPUTS}" \
  #--verbosity=debug 

