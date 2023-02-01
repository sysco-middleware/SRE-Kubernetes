#!/bin/bash

# Input variables
SUBSCRIPTION_ID=""
SERVICE_PRINCIPAL_ID=""
SERVICE_PRINCIPAL_SECRET=""
TENANT_ID=""

usage() {
    echo
    echo " Usage:"
    echo "     $0 -t <TENANT_ID> -s <SUBSCRIPTION_ID> -u <SERVICE_PRINCIPAL_ID> -p <SERVICE_PRINCIPAL_SECRET>"
    echo "         TENANT_ID                  (required)"
    echo "         SUBSCRIPTION_ID            (required)"
    echo "         SERVICE_PRINCIPAL_ID       (required)"
    echo "         SERVICE_PRINCIPAL_SECRET   (required)"
    echo
    exit 1
}

# Check for input variables
while getopts ":t:s:u:p:" OPT; do
  case ${OPT} in
    t )
      TENANT_ID=$OPTARG
      ;;
    s )
      SUBSCRIPTION_ID=$OPTARG
      ;;
    u )
      SERVICE_PRINCIPAL_ID=$OPTARG
      ;;
    p )
      SERVICE_PRINCIPAL_SECRET=$OPTARG
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
if [ -z "${TENANT_ID}" ] || [ -z "${SUBSCRIPTION_ID}" ] || [ -z "${SERVICE_PRINCIPAL_ID}" ] || [ -z "${SERVICE_PRINCIPAL_SECRET}" ]; then
  echo
  echo -e "\e[31m  »»» 💥 Error: -t <TENANT_ID> -s <SUBSCRIPTION_ID> -u <SERVICE_PRINCIPAL_ID> -p <SERVICE_PRINCIPAL_SECRET> required."
  usage
fi

az login \
    --service-principal \
    --username "${SERVICE_PRINCIPAL_ID}" \
    --password "${SERVICE_PRINCIPAL_SECRET}" \
    --tenant "${TENANT_ID}"

az account set -s "${SUBSCRIPTION_ID}"