#!/bin/bash

# Usage:
# bash scripts/validate-requirements.sh "END_USER_EMAIL" "ORGANIZATION_ID" "BILLING_ACCOUNT_ID"

# -------------------------- Variables --------------------------
# Expected versions of the installers
TF_VERSION="1.3.0"
OCI_CLI_VERSION="3.20.0"
#GIT_VERSION="2.28.0"

# Input variables
PARENT_COMPARTMENT_OCID=""
TENANT_OCID=""
SERVICE_PRINCIPAL_OCID=""
TENANT_NAME=""
SERVICE_PRINCIPAL_NAME=""
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

# Create Compartment
function create_compartment(){
    echo -e "\n\e[34m»»» 📦 \e[96mCreating Compartment\e[0m..."
    oci iam compartment create --compartment-id $PARENT_COMPARTMENT_OCID --name $tf_var_management_Compartment --description "Created by Terrafrom for $tf_var_resource_prefix purpose"
}

# Create Blob Container
function create_object_storage_bucket(){
    echo -e "\n\e[34m»»» 🫙 \e[96m Creating Object Storage Bucket\e[0m..."
    # need a code to wait till the compartment is available fully
    MGMT_COMPARTMENT_ID="$(oci iam compartment list --compartment-id-in-subtree true --name $tf_var_management_Compartment | jq -r '.data[].id')"
    oci os bucket create --compartment-id $MGMT_COMPARTMENT_ID --name $tf_var_management_BucketName --versioning Enabled
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
    # sed -i "s/resource_group_name  = .*/resource_group_name  = \"$tf_var_management_ResourceGroup\"/g" $BACKEND_FILE
    # sed -i "s/storage_account_name = .*/storage_account_name = \"$tf_var_management_StorageAccountName\"/g" $BACKEND_FILE
    # sed -i "s/container_name       = .*/container_name       = \"$tf_var_management_ContainerName\"/g" $BACKEND_FILE
    # sed -i "s/key                  = .*/key                  = \"$tf_var_state_name\"/g" $BACKEND_FILE

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
    OCI_CONFIG="$(echo $HOME/.oci/config)"
    BACKEND_FILE="$(echo $BOOTSTRAP_DIR)/backend.tf"
    TFVARS_FILE="$(echo $BOOTSTRAP_DIR)/terraform.tfvars"
    ENV_FILE="$(echo $BOOTSTRAP_DIR)/.env"
    CLEANUP_SCRIPT="$(echo $BOOTSTRAP_DIR)/scripts/cleanup-rg.sh"
    VALIDATION_SCRIPT="$(echo $BOOTSTRAP_DIR)/scripts/validate-requirements.sh"

    validate_env_file
    
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
                    $(echo $VALIDATION_SCRIPT -c $PARENT_COMPARTMENT_OCID)
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

    echo -e "\n\e[34m»»» ✅ \e[96mGetting the environment details...\n"
    export TENANT_OCID="$(sed -rn 's/tenancy=(.*)/\1/p' $OCI_CONFIG 2> /dev/null)"
    export SERVICE_PRINCIPAL_OCID="$(sed -rn 's/user=(.*)/\1/p' $OCI_CONFIG 2> /dev/null)"
    export REGION="$(sed -rn 's/region=(.*)/\1/p' $OCI_CONFIG 2> /dev/null)"
    export PARENT_COMPARTMENT_NAME="$(oci iam compartment get --compartment-id $PARENT_COMPARTMENT_OCID | jq -r '.data.name')"
    SERVICE_PRINCIPAL_NAME="$(oci iam user get --user-id $SERVICE_PRINCIPAL_OCID | jq -r '.data.name')"
    TENANT_NAME="$(oci iam tenancy get --tenancy-id $TENANT_OCID | jq -r '.data.name')"

    echo ""
    echo ""
    echo -e "\n\e[34m🔨 \e[96mOCI details from logged on user \e[0m"
    echo -e "\e[34m\t• \e[96mTenant:                        \e[33m$TENANT_NAME\e[0m"
    echo -e "\e[34m\t• \e[96mParent Compartment Name:       \e[33m$PARENT_COMPARTMENT_NAME\e[0m"
    echo -e "\e[34m\t• \e[96mmUser:                         \e[33m$SERVICE_PRINCIPAL_NAME\e[0m"
    echo -e "\e[34m\t• \e[96mRegion:                        \e[33m$REGION\e[0m\n"
    echo -e "\n\e[34m»»» 📝 \e[96mNow you can start the bootstrap process using - $BOOTSTRAP_SCRIPT\e[0m"

    read -p "- Are these details correct, do you want to continue (y/n)? " answer
    case ${answer:0:1} in
        y|Y )
        ;;
        * )
            echo -e "\e[31m»»» 😲 Deployment canceled\e[0m\n"
            exit
        ;;
    esac

    create_compartment

    create_object_storage_bucket

    # terraform_init

    # terraform_import_SA_RG_into_State
    
}


usage() {
    echo
    echo " Usage:"
    echo "     $0 -c <PARENT_COMPARTMENT_OCID>"
    echo "         PARENT_COMPARTMENT_OCID         (required)"
    echo
    exit 1
}

# Check for input variables
while getopts ":c:" OPT; do
  case ${OPT} in
    c )
      PARENT_COMPARTMENT_OCID=$OPTARG
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
if [ -z "${PARENT_COMPARTMENT_OCID}" ]; then
  echo
  echo -e "\e[31m  »»» 💥 Error: -c <PARENT_COMPARTMENT_OCID> required.\e[0m"
  usage
fi


echo -e "\n\e[34m╔══════════════════════════════════════╗"
echo -e "║\e[33m   Terraform Backend Bootstrap! 🥾\e[34m    ║"
echo -e "║\e[32m        One time setup script \e[34m        ║"
echo -e "╚══════════════════════════════════════╝"

main
