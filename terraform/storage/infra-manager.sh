#!/bin/bash
#
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eo pipefail
[ ! -z "${TRACE:-}" ] && set -x

log() {
  echo "* [${2:-INFO}] $1"
}

die() {
  log >&2 "$1" "ERROR"
  exit 1
}

# usage() {
#   echo """
#   usage: $0 [-p <project>] [-e <environment>] <provider>/<layer> <action>
#     where
#       -p project name (defaults to TF_VAR_project env var)
#       -e environment name (defaults to TF_VAR_environment env var)
#       provider is 'do', 'k8s', etc
#       layer is 'core', etc
#       action is one of 'plan', 'apply', or 'destroy'
#   """
# }

# check_args() {
#   if [ -z "$project" ] || \
#      [ -z "$environment" ] || \
#      [ -z "$provider" ] || \
#      [ -z "$layer" ] || \
#      [ -z "$action" ]; then
#     usage
#     die 'need args'
#   fi
# }

GCLOUD_VERSION="alpha"

get_latest_revision_of() {
  local deployment=$1
  local latest_revision=$(gcloud ${GCLOUD_VERSION} infra-manager deployments describe ${deployment} --format json | jq '.latestRevision' -r )
  echo "${latest_revision}"
}
get_deployment_output() {
  local project=$1
  local location=$2
  local deployment_name=$3
  local output_name=$4

  local deployment="projects/${project}/locations/${location}/deployments/${deployment_name}"
  local latest_revision="$(get_latest_revision_of ${deployment})"
  local output_value=$(gcloud ${GCLOUD_VERSION} infra-manager revisions describe ${latest_revision} --format json | jq ".applyResults|.outputs[\"${output_name}\"]|.value" -r )

  #echo ${output_value}
  # or
  echo $(basename ${output_value})
}

# already set in cloudshell environment: GOOGLE_CLOUD_PROJECT="my-project-name"
DEPLOYMENT_NAME="storage"
DEPLOYMENT_ZONE="us-central1-c"
DEPLOYMENT_GIT_REPO="https://github.com/mmm/gcp-standalone-partition"
DEPLOYMENT_GIT_DIRECTORY="terraform/storage"

SERVICE_ACCOUNT_PROJECT_ID="${GOOGLE_CLOUD_PROJECT}"
SERVICE_ACCOUNT_EMAIL="config-agent@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com"
DEPLOYMENT_REGION="${DEPLOYMENT_ZONE%-*}"
NETWORK_NAME="$(get_deployment_output ${GOOGLE_CLOUD_PROJECT} ${DEPLOYMENT_REGION} network network_id)"
SUBNET_NAME="$(get_deployment_output ${GOOGLE_CLOUD_PROJECT} ${DEPLOYMENT_REGION} network subnet_id)"
INPUTS="project_id=${GOOGLE_CLOUD_PROJECT},network=${NETWORK_NAME},subnet=${SUBNET_NAME},zone=${DEPLOYMENT_ZONE}"

echo gcloud ${GCLOUD_VERSION} infra-manager deployments apply \
  "projects/${GOOGLE_CLOUD_PROJECT}/locations/${DEPLOYMENT_REGION}/deployments/${DEPLOYMENT_NAME}" \
  --service-account "projects/${SERVICE_ACCOUNT_PROJECT_ID}/serviceAccounts/${SERVICE_ACCOUNT_EMAIL}" \
  --git-source-repo="${DEPLOYMENT_GIT_REPO}" \
  --git-source-directory="${DEPLOYMENT_GIT_DIRECTORY}" \
  --input-values="${INPUTS}"

#[ ! -z "${TRACE:-}" ] && --verbosity=debug

