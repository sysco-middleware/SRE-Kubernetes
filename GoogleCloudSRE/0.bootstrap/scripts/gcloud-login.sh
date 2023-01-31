#!/bin/bash

# Input variables
PROJECT_ID=""
SERVICE_ACCOUNT_ID=""
SERVICE_PRINCIPAL_KEY=""
ORGANIZATION_ID=""

usage() {
    echo
    echo " Usage:"
    echo "     $0 -p <PROJECT_ID> -u <SERVICE_ACCOUNT_ID> -k <SERVICE_PRINCIPAL_KEY>"
    echo "         PROJECT_ID            (required)"
    echo "         SERVICE_ACCOUNT_ID       (required)"
    echo "         SERVICE_PRINCIPAL_KEY   (required)"
    echo
    exit 1
}

# Check for input variables
while getopts ":t:s:u:p:" OPT; do
  case ${OPT} in
    p )
      PROJECT_ID=$OPTARG
      ;;
    u )
      SERVICE_ACCOUNT_ID=$OPTARG
      ;;
    k )
      SERVICE_PRINCIPAL_KEY=$OPTARG
      ;;
    : )
      echo
      echo " Error: option -${OPTARG} requires an argument"
      usage
      ;;
   \? )
      echo
      echo " Error: invalid option -${OPTARG}"
      usage
      ;;
  esac
done
shift $((OPTIND -1))

# Check for required input variables
if [ -z "${PROJECT_ID}" ] || [ -z "${SERVICE_ACCOUNT_ID}" ] || [ -z "${SERVICE_PRINCIPAL_KEY}" ]; then
  echo
  echo -e "\e[31m  »»» 💥 Error: -p <PROJECT_ID> -u <SERVICE_ACCOUNT_ID> -k <SERVICE_PRINCIPAL_KEY> required."
  usage
fi

gcloud auth \
  activate-service-account \
    "${SERVICE_ACCOUNT_ID}" \
    --key-file="${SERVICE_PRINCIPAL_KEY}" \
    # --key-file=/path/key.json \
    --project="${PROJECT_ID}"

gcloud config set project "${PROJECT_ID}"