#!/bin/bash

# Usage:
# bash scripts/validate-requirements.sh "END_USER_EMAIL" "ORGANIZATION_ID" "BILLING_ACCOUNT_ID"

# -------------------------- Variables --------------------------
# Expected versions of the installers
TF_VERSION="1.3.0"
GCLOUD_CLI_VERSION="393.0.0"
#GIT_VERSION="2.28.0"

# Input variables
PROJECT_ID=""
SERVICE_PRINCIPAL_ID=""
SERVICE_PRINCIPAL_KEY=""
ORGANIZATION_ID=""

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


# Create GCS
function create_gcs(){
    echo -e "\n\e[34m»»» 💾 \e[96mCreating gcs\e[0m..."
    gcloud storage ls
    # gcloud storage buckets create gs://$tf_var_management_BucketName --project=$tf_var_management_ProjectID --location=$tf_var_management_Location
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
    echo -e "\n\e[34m»»» 📤 \e[96mUpdating the $BACKEND_FILE file with variables from .env file...\e[0m..."
    validate_env_file
    sed -i "s/bucket = .*/bucket = \"$tf_var_management_BucketName\"/g" $BACKEND_FILE
    sed -i "s/prefix = .*/prefix = \"$tf_var_resource_prefix\"/g" $BACKEND_FILE

    echo -e "\n\e[34m»»» 📤 \e[96mUpdating the tfvars file with variables from .env file...\e[0m..."
    sed "s/=/ = /g" $ENV_FILE | tee $TFVARS_FILE 2>&1 > /dev/null

    echo -e "\n\e[34m»»» ✨ \e[96mTerraform init\e[0m..."
    cd $BOOTSTRAP_DIR
    # terraform init -reconfigure
}

# Import the storage account & res group into state
function terraform_import_into_State(){
    echo -e "\n\e[34m»»» 📤 \e[96mImporting resources to state\e[0m..."
    cd $BOOTSTRAP_DIR
    # terraform import google_storage_bucket.tfstate $tf_var_management_ProjectID/$tf_var_management_BucketName
    echo "terraform import google_storage_bucket.tfstate $tf_var_management_ProjectID/$tf_var_management_BucketName"
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
            sed -i "s/DELETE_RG=.*/DELETE_RG=$tf_var_management_ProjectID/g" $CLEANUP_SCRIPT
        ;;
        * )
            read -p "- Do you want to run the validation script ($VALIDATION_SCRIPT) (y/n)? " answer
            case ${answer:0:1} in
                y|Y )
                    echo -e "\n\e[34m»»» 📝 \e[96mStarting the Validation process...\e[0m"
                    $(echo $VALIDATION_SCRIPT -u $SERVICE_PRINCIPAL_ID -p $PROJECT_ID)
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

    gcloud config set project "${PROJECT_ID}"
    export PROJECT_ID=$(gcloud config get-value project 2> /dev/null)
    export SERVICE_PRINCIPAL_ID=$(gcloud config get-value account 2> /dev/null)
    echo ""
    echo ""
    echo -e "\e[34m»»»   • \e[96mProject ID:       \e[33m$PROJECT_ID\e[0m"
    echo -e "\e[34m»»»   • \e[96mUser:       \e[33m$SERVICE_PRINCIPAL_ID\e[0m\n"
    read -p "- Are these details correct, do you want to continue (y/n)? " answer
    case ${answer:0:1} in
        y|Y )
        ;;
        * )
            echo -e "\e[31m»»» 😲 Deployment canceled\e[0m\n"
            exit
        ;;
    esac

    create_gcs

    terraform_init

    terraform_import_into_State
    
}


usage() {
    echo
    echo " Usage:"
    echo "     $0 -o <ORGANIZATION_ID> -p <PROJECT_ID> -u <SERVICE_PRINCIPAL_ID> -k <SERVICE_PRINCIPAL_KEY>"
    echo "         ORGANIZATION_ID                  (required)"
    echo "         PROJECT_ID            (required)"
    echo "         SERVICE_PRINCIPAL_ID       (required)"
    echo "         SERVICE_PRINCIPAL_KEY   (required)"
    echo
    echo -e "\e[0m"
    exit 1
}

# Check for input variables
while getopts ":t:s:u:p:" OPT; do
  case ${OPT} in
    o )
      ORGANIZATION_ID=$OPTARG
      ;;
    p )
      PROJECT_ID=$OPTARG
      ;;
    u )
      SERVICE_PRINCIPAL_ID=$OPTARG
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
# if [ -z "${ORGANIZATION_ID}" ] || [ -z "${PROJECT_ID}" ] || [ -z "${SERVICE_PRINCIPAL_ID}" ] || [ -z "${SERVICE_PRINCIPAL_KEY}" ]; then
if [ -z "${PROJECT_ID}" ] || [ -z "${SERVICE_PRINCIPAL_ID}" ]; then
  echo
  echo -e "\e[31m  »»» 💥 Error: -t <ORGANIZATION_ID> -p <PROJECT_ID> -u <SERVICE_PRINCIPAL_ID> -p <SERVICE_PRINCIPAL_KEY> required."
  usage
fi

echo -e "\n\e[34m╔══════════════════════════════════════╗"
echo -e "║\e[33m   Terraform Backend Bootstrap! 🥾\e[34m    ║"
echo -e "║\e[32m        One time setup script \e[34m        ║"
echo -e "╚══════════════════════════════════════╝"

main
