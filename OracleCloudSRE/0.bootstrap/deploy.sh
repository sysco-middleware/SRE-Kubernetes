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

# Collect the errors
ERRORS=""

# -------------------------- Functions ---------------------------

function validate_env_file(){
    echo -e "\n\e[34m»»» ✅ \e[96mValidating env file..."
    ENV_FILE="$(find "$(cd ..; pwd)" -name ".env" 2>/dev/null)"

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

# Set up Terraform
function terraform_init(){
    echo -e "\n\e[34m»»» ✨ \e[96mTerraform init\e[0m..."
    cd $BOOTSTRAP_DIR
    terraform init -reconfigure
}

function terraform_plan(){
    echo -e "\n\e[34m»»» 📜 \e[96mTerraform plan\e[0m...\n"
    BOOTSTRAP_DIR="$(find "$(cd ..; pwd)" -name "0.bootstrap" 2>/dev/null)"
    cd $BOOTSTRAP_DIR
    terraform plan
}

function terraform_run(){
    echo -e "\n\e[34m»»» 🚀 \e[96mTerraform apply\e[0m...\n"
    BOOTSTRAP_DIR="$(find "$(cd ..; pwd)" -name "0.bootstrap" 2>/dev/null)"
    cd $BOOTSTRAP_DIR
    terraform apply -auto-approve
}


function main(){
    # variables used
    BOOTSTRAP_DIR="$(find "$(cd ..; pwd)" -name "0.bootstrap" 2>/dev/null)"
    OCI_CONFIG="$(echo $HOME/.oci/config)"
    ENV_FILE="$(echo $BOOTSTRAP_DIR)/.env"
    CLEANUP_SCRIPT="$(echo $BOOTSTRAP_DIR)/scripts/cleanup-rg.sh"
    BOOTSTRAP_SCRIPT="$(find "$(cd ..; pwd)" -name "bootstrap.sh" 2>/dev/null)"

    validate_env_file
    
    # Run bootstrap script
    echo -e "\e[0m"
    read -p "- Have you run the bootstrap script ($BOOTSTRAP_SCRIPT) (y/n)? " answer
    case ${answer:0:1} in
        y|Y )
        ;;
        * )
            read -p "- Do you want to run the bootstrap script ($BOOTSTRAP_SCRIPT) (y/n)? " answer
            case ${answer:0:1} in
                y|Y )
                    echo -e "\n\e[34m»»» 📝 \e[96mStarting the Bootstrap process...\e[0m"
                    # $(echo $BOOTSTRAP_SCRIPT -u $SERVICE_PRINCIPAL_ID -p $SERVICE_PRINCIPAL_SECRET -s $SUBSCRIPTION_ID -t $TENANT_ID)
                    $(echo $BOOTSTRAP_SCRIPT -s $SUBSCRIPTION_ID -t $TENANT_ID)
                    exit
                ;;
                * )
                    echo -e "\e[31m»»» 🚫 Deployment canceled\e[0m"
                    echo -e "\e[31m»»»  🚀 Execute \"$BOOTSTRAP_SCRIPT\" before proceeding\e[0m\n"
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

    export TENANT_OCID="$(sed -rn 's/tenancy=(.*)/\1/p' $OCI_CONFIG 2> /dev/null)"
    export SERVICE_PRINCIPAL_OCID="$(sed -rn 's/user=(.*)/\1/p' $OCI_CONFIG 2> /dev/null)"
    export REGION="$(sed -rn 's/region=(.*)/\1/p' $OCI_CONFIG 2> /dev/null)"
    export PARENT_COMPARTMENT_NAME="$(oci iam compartment get --compartment-id $PARENT_COMPARTMENT_OCID | jq '."data"."name"')"
    SERVICE_PRINCIPAL_NAME="$(oci iam user get --user-id $SERVICE_PRINCIPAL_OCID | jq '."data"."name"')"
    TENANT_NAME="$(oci iam tenancy get --tenancy-id $TENANT_OCID | jq '."data"."name"')"

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

    # terraform_init

    # terraform_plan

    # terraform_run
    
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
