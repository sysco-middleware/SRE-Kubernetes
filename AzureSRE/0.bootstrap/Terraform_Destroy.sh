#!/bin/bash

# Usage:
# bash scripts/validate-requirements.sh "END_USER_EMAIL" "ORGANIZATION_ID" "BILLING_ACCOUNT_ID"

# -------------------------- Variables --------------------------
# Expected versions of the installers
TF_VERSION="1.3.0"
AZURE_CLI_VERSION="2.40.0"
#GIT_VERSION="2.28.0"

# Input variables
SUBSCRIPTION_ID=""
SERVICE_PRINCIPAL_ID=""
SERVICE_PRINCIPAL_SECRET=""
TENANT_ID=""

# Collect the errors
ERRORS=""

# -------------------------- Functions ---------------------------


function terraform_init(){
    # sed -i "s/resource_group_name  = .*/resource_group_name  = \"$tf_var_management_ResourceGroup\"/g" $BACKEND_FILE
    # sed -i "s/storage_account_name = .*/storage_account_name = \"$tf_var_management_StorageAccountName\"/g" $BACKEND_FILE
    # sed -i "s/container_name       = .*/container_name       = \"$tf_var_management_ContainerName\"/g" $BACKEND_FILE
    # sed -i "s/key                  = .*/key                  = \"$tf_var_state_name\"/g" $BACKEND_FILE

    export ARM_CLIENT_ID=$SERVICE_PRINCIPAL_ID
    export ARM_CLIENT_SECRET=$SERVICE_PRINCIPAL_SECRET
    export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
    export ARM_TENANT_ID=$TENANT_ID

    echo -e "\n\e[34m»»» ✨ \e[96mTerraform init\e[0m..."
    cd $BOOTSTRAP_DIR
    terraform init
}

function terraform_destroy(){
    echo -e "\e[34m»»»   • \e[96mInitiating Terrafrom Destroy \e[0m\n"
    read -p "- Are you sure to run Terraform Destroy ? (y/n)? " answer
    case ${answer:0:1} in
        y|Y )
        terraform destroy
        ;;
        * )
            echo -e "\e[31m»»» 😶 Terrafrom Destroy canceled\e[0m\n"
            exit
        ;;
    esac

    
}

function main(){
    # variables used
    BOOTSTRAP_DIR="$(find "$(cd ..; pwd)" -name "0.bootstrap" 2>/dev/null)"
    BACKEND_FILE="$(echo $BOOTSTRAP_DIR)/backend.tf"
    TFVARS_FILE="$(echo $BOOTSTRAP_DIR)/terraform.tfvars"
    TFPROVIDER_FILE="$(echo $BOOTSTRAP_DIR)/provider.tf"
    ENV_FILE="$(echo $BOOTSTRAP_DIR)/.env"
    CLEANUP_SCRIPT="$(echo $BOOTSTRAP_DIR)/scripts/cleanup-rg.sh"
    VALIDATION_SCRIPT="$(echo $BOOTSTRAP_DIR)/scripts/validate-requirements.sh"

    validate_env_file
    
    # Run validatation script
    echo -e "\e[0m"

    az account set --subscription $SUBSCRIPTION_ID
    export SUBSCRIPTION_NAME=$(az account show --query name -o tsv 2> /dev/null)
    export SUBSCRIPTION_ID=$(az account show --query id -o tsv 2> /dev/null)
    export TENANT_ID=$(az account show --query tenantId -o tsv 2> /dev/null)
    export SUBSCRIPTION_USER="$(az account show --query user.name -o tsv 2> /dev/null)"
    echo ""
    echo ""
    echo -e "\e[34m»»» 🔨 \e[96mAzure details from logged on user \e[0m"
    echo -e "\e[34m»»»   • \e[96mSubscription: \e[33m$SUBSCRIPTION_NAME\e[0m"
    echo -e "\e[34m»»»   • \e[96mTenant:       \e[33m$TENANT_ID\e[0m"
    echo -e "\e[34m»»»   • \e[96mUser:       \e[33m$SUBSCRIPTION_USER\e[0m\n"
    read -p "- Are these details correct, do you want to continue (y/n)? " answer
    case ${answer:0:1} in
        y|Y )
        ;;
        * )
            echo -e "\e[31m»»» 😲 Action Canceled\e[0m\n"
            exit
        ;;
    esac

    terraform_init
    
    terraform_destroy
}

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
  echo -e "\e[31m  »»» 💥 Error: -t <TENANT_ID> -s <SUBSCRIPTION_ID> -u <SERVICE_PRINCIPAL_ID> -p <SERVICE_PRINCIPAL_SECRET> required.\e[0m"
  usage
fi

echo -e "\n\e[34m╔══════════════════════════════════════╗"
echo -e "║\e[33m   Terraform Backend Bootstrap! 🥾\e[34m    ║"
echo -e "║\e[32m        One time setup script \e[34m        ║"
echo -e "╚══════════════════════════════════════╝"

main
