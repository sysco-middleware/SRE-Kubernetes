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

function validate_env_file(){
    echo -e "\n\e[34m»»» ✅ \e[96mValidating env file..."
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "\e[31m   💥 Unable to find .env file, please create file and try again!"
        exit
    elif [ "$(/bin/grep -c CHANGE_ME "$ENV_FILE")" != 0 ]; then
        echo "  .env must have required values fulfilled."
        ERRORS+=$'  .env file must be correctly fulfilled for 0-bootstrap step.\n'
        exit
    else
    # Load env variables from .env file
    echo -e "\n\e[34m   🧩 \e[96mLoading environmental variables\e[0m..."
    export $(/bin/grep -v '^#' "$ENV_FILE" | xargs)
    fi
}

# Create Resource Group
function create_resource_group(){
    echo -e "\n\e[34m»»» 📦 \e[96mCreating resource group\e[0m..."
    az group create --resource-group $tf_var_management_ResourceGroup --location $tf_var_management_Region -o table
}

# Create Storage Account
function create_storage_account(){
    echo -e "\n\e[34m»»» 💾 \e[96mCreating storage account\e[0m..."
    az storage account create --resource-group $tf_var_management_ResourceGroup --name $tf_var_management_StorageAccountName --location $tf_var_management_Region --kind StorageV2 --encryption-services blob --sku Standard_LRS -o table
    ACCOUNT_KEY=$(az storage account keys list --resource-group $tf_var_management_ResourceGroup --account-name $tf_var_management_StorageAccountName --query '[0].value' -o tsv)
    export ARM_ACCESS_KEY=$ACCOUNT_KEY
}

# Create Blob Container
function create_blob_container(){
    echo -e "\n\e[34m»»» 🫙 \e[96m Creating blob container\e[0m..."
    SA_ACCESS_KEY=$(az storage account keys list --resource-group $tf_var_management_ResourceGroup --account-name $tf_var_management_StorageAccountName --query '[0].value' -o tsv)
    az storage container create --account-name $tf_var_management_StorageAccountName --name $tf_var_management_ContainerName --account-key $SA_ACCESS_KEY -o table
}

# Checks if initial config was done for 0-bootstrap step
function validate_bootstrap_step(){
    echo -e "\n\e[34m»»» ✅ \e[96mValidating 0-bootstrap configuration..."
    SCRIPTS_DIR="$( dirname -- "$0"; )"
    FILE="$SCRIPTS_DIR/../0-bootstrap/terraform.tfvars"
    if [ ! -f "$FILE" ]; then
        echo "  Rename the file 0-bootstrap/terraform.example.tfvars to 0-bootstrap/terraform.tfvars"
        ERRORS+=$'  terraform.tfvars file must exist for 0-bootstrap step.\n'
    else
        if [ "$(grep -c REPLACE_ME "$FILE")" != 0 ]; then
            echo "  0-bootstrap/terraform.tfvars must have required values fulfilled."
            ERRORS+=$'  terraform.tfvars file must be correctly fulfilled for 0-bootstrap step.\n'
        fi
    fi
}

function terraform_init(){
    sed -i "s/resource_group_name  = .*/resource_group_name  = \"$tf_var_management_ResourceGroup\"/g" $BACKEND_FILE
    sed -i "s/storage_account_name = .*/storage_account_name = \"$tf_var_management_StorageAccountName\"/g" $BACKEND_FILE
    sed -i "s/container_name       = .*/container_name       = \"$tf_var_management_ContainerName\"/g" $BACKEND_FILE
    sed -i "s/key                  = .*/key                  = \"$tf_var_state_name\"/g" $BACKEND_FILE

    echo -e "\n\e[34m»»» 📤 \e[96mUpdating the tfvars file with varibales from .env file...\e[0m..."
    validate_env_file
    sed "s/=/ = /g" $ENV_FILE | tee $TFVARS_FILE 2>&1 > /dev/null

    echo -e "\n\e[34m»»» ✨ \e[96mTerraform init\e[0m..."
    cd $BOOTSTRAP_DIR
    terraform init -reconfigure
}

# Import the storage account & res group into state
function terraform_import_SA_RG_into_State(){
    echo -e "\n\e[34m»»» 📤 \e[96mImporting resources to state\e[0m..."
    cd $BOOTSTRAP_DIR
    terraform import azurerm_resource_group.tfstate "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$tf_var_management_ResourceGroup"
    terraform import azurerm_storage_account.tfstate "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$tf_var_management_ResourceGroup/providers/Microsoft.Storage/storageAccounts/$tf_var_management_StorageAccountName"
    terraform import azurerm_storage_container.tfstate "https://$tf_var_management_StorageAccountName.blob.core.windows.net/$tf_var_management_ContainerName"
}

function main(){
    # variables used
    BOOTSTRAP_DIR="$(find "$(cd ..; pwd)" -name "0.bootstrap" 2>/dev/null)"
    BACKEND_FILE="$(echo $BOOTSTRAP_DIR)/backend.tf"
    TFVARS_FILE="$(echo $BOOTSTRAP_DIR)/terraform.tfvars"
    ENV_FILE="$(echo $BOOTSTRAP_DIR)/.env"
    CLEANUP_SCRIPT="$(echo $BOOTSTRAP_DIR)/scripts/cleanup-rg.sh"
    VALIDATION_SCRIPT="$(echo $BOOTSTRAP_DIR)/scripts/validate-requirements.sh"
    
    # Run validatation script
    echo -e "\e[0m"
    read -p "- Have you run the validation script ($VALIDATION_SCRIPT) (y/n)? " answer
    case ${answer:0:1} in
        y|Y )
            echo -e "\n\e[34m»»» 📝 \e[96mUpdating $CLEANUP_SCRIPT with Resource Group name incase you want to cleanup later...\e[0m"
            sed -i "s/DELETE_RG=.*/DELETE_RG=$tf_var_management_ResourceGroup/g" $CLEANUP_SCRIPT
        ;;
        * )
            read -p "- Do you want to run the validation script ($VALIDATION_SCRIPT) (y/n)? " answer
            case ${answer:0:1} in
                y|Y )
                    echo -e "\n\e[34m»»» 📝 \e[96mStarting the Validation process...\e[0m"
                    $(echo $VALIDATION_SCRIPT -u $SERVICE_PRINCIPAL_ID -p $SERVICE_PRINCIPAL_SECRET -s $SUBSCRIPTION_ID -t $TENANT_ID)
                    exit
                ;;
                * )
                    echo -e "\e[31m»»» 🚫 Bootstrap canceled\e[0m"
                    echo -e "\e[31m»»»  🚀 Execute \"$SCRIPTS_DIR/scripts/validate-requirements.sh\" before proceeding\e[0m\n"
                    exit
                ;;
            esac
        ;;
    esac

    validate_env_file
    
    validate_bootstrap_step

    # echo "......................................."
    # if [ -z "$ERRORS" ]; then
    #     echo "Validation successful!"
    #     echo "No errors found."
    # else
    #     echo -e "\e[31m  »»» 💥 Validation failed!"
    #     echo -e "\e[31m  »»» 💥 Errors found:"
    #     echo "$ERRORS"
    # fi

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
            echo -e "\e[31m»»» 😲 Deployment canceled\e[0m\n"
            exit
        ;;
    esac

    create_resource_group

    create_storage_account

    create_blob_container

    terraform_init

    terraform_import_SA_RG_into_State
    
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
# if [ -z "${TENANT_ID}" ] || [ -z "${SUBSCRIPTION_ID}" ] || [ -z "${SERVICE_PRINCIPAL_ID}" ] || [ -z "${SERVICE_PRINCIPAL_SECRET}" ]; then
if [ -z "${TENANT_ID}" ] || [ -z "${SUBSCRIPTION_ID}" ]; then
  echo
#   echo -e "\e[31m  »»» 💥 Error: -t <TENANT_ID> -s <SUBSCRIPTION_ID> -u <SERVICE_PRINCIPAL_ID> -p <SERVICE_PRINCIPAL_SECRET> required."
  echo -e "\e[31m  »»» 💥 Error: -t <TENANT_ID> -s <SUBSCRIPTION_ID> -u <SERVICE_PRINCIPAL_ID> -p <SERVICE_PRINCIPAL_SECRET> required.\e[0m"
  usage
fi

echo -e "\n\e[34m╔══════════════════════════════════════╗"
echo -e "║\e[33m   Terraform Backend Bootstrap! 🥾\e[34m    ║"
echo -e "║\e[32m        One time setup script \e[34m        ║"
echo -e "╚══════════════════════════════════════╝"

main
