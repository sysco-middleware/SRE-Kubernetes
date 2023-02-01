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

# Compare two semantic versions
# returns:
# 0 = $1 is equal $2
# 1 = $1 is higher than $2
# 2 = $1 is lower than $2
function compare_version(){

    # when both inputs are the equal, just return 0
    if [[ "$1" == "$2" ]]; then
        echo 0
        return 0
    fi

    local version1=("$1")
    local version2=("$2")
    # completing with zeroes on $1 so it can have the same size than $2
    for ((i=${#version1[@]}; i<${#version2[@]}; i++))
    do
        version1[i]=0
    done
    for ((i=0; i<${#version1[@]}; i++))
    do
        # completing with zeroes on $2 so it can have the same size than $1
        if [[ -z ${version2[i]} ]]; then
            version2[i]=0
        fi
        # if the number at index i for $1 is higher than $2, return 1
        if [[ ${version1[i]} > ${version2[i]} ]]; then
            echo 1
            return 1
        fi
        # if the number at index i for $1 is lower than $2, return 2
        if [[ ${version1[i]} < ${version2[i]} ]]; then
            echo 2
            return 2
        fi
    done
    return 0
}

# Echoes messages for cases where an installation is missing
# $1 = name of the missing binary
# $2 = web site to find the installation details of the missing binary
function echo_missing_installation () {
    local binary_name=$1
    local installer_url=$2

    echo -e "\e[31m   ⚠️ $binary_name not found."
    echo -e "\e[31m   😥 Visit $installer_url and follow the instructions to install $binary_name."
}

# Echoes messages for cases where an installation version is incompatible
# $1 = name of the missing binary
# $2 = "at least" / "equal"
# $3 = version to be displayed
# $4 = web site to find the installation details of the missing binary
# $5 = current version

function echo_wrong_version () {
    local binary_name=$1
    local constraint=$2
    local target_version=$3
    local installer_url=$4
    local current_version=$5

    echo "  An incompatible $binary_name version, $current_version, was found."
    echo "  Version required should be $constraint $target_version"
    echo "  Visit $installer_url and follow the instructions to install $binary_name."
}

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

# Validate the Terraform installation and version
function validate_terraform(){
    echo -e "\n\e[34m»»» ✅ \e[96mValidating Terraform installation..."
    if [ ! "$(command -v terraform )" ]; then
        echo_missing_installation "Terraform" "https://learn.hashicorp.com/tutorials/terraform/install-cli"
        ERRORS+=$'  Terraform not found\n'
    else
        TERRAFORM_CURRENT_VERSION=$(terraform version -json | jq -r .terraform_version)
        if [ "$(compare_version "$TERRAFORM_CURRENT_VERSION" "$TF_VERSION")" -gt 1 ]; then
            echo_wrong_version "Terraform" "greater than or equal to" "$TF_VERSION" "https://learn.hashicorp.com/tutorials/terraform/install-cli" "$TERRAFORM_CURRENT_VERSION"
            ERRORS+=$'  Terraform version is incompatible.\n'
        fi
        echo -e "\n\e[34m\t👍 \e[96mTerraform Version found: $TERRAFORM_CURRENT_VERSION"
    fi
}

# Validate the OCI cli installation and version
function validate_oci_cli(){
    echo -e "\n\e[34m»»» ✅ \e[96mValidating OCI CLI installation..."
    if [ ! "$(command -v oci)" ]; then
        echo_missing_installation "OCI CLI" "https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
        ERRORS+=$'  oci cli not found.\n'
    else
        OCI_CURRENT_VERSION=$(oci --version)
        if [ "$(compare_version "$OCI_CURRENT_VERSION" "$OCI_CLI_VERSION")" -eq 2 ]; then
            echo_wrong_version "OCI CLI" "at least" "$OCI_CLI_VERSION" "https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm" "$OCI_CURRENT_VERSION"
            ERRORS+=$'  OCI CLI version is incompatible.\n'
        fi
        echo -e "\n\e[34m\t👍 \e[96mOCI CLI Version found: $OCI_CURRENT_VERSION"
    fi
}

# Validate the configuration of the OCI CLI
function validate_oci_configuration(){
    echo -e "\n\e[34m»»» ✅ \e[96mValidating oci configuration..."
    export TENANT_OCID="$(sed -rn 's/tenancy=(.*)/\1/p' $OCI_CONFIG 2> /dev/null)"
    export SERVICE_PRINCIPAL_OCID="$(sed -rn 's/user=(.*)/\1/p' $OCI_CONFIG 2> /dev/null)"
    export REGION="$(sed -rn 's/region=(.*)/\1/p' $OCI_CONFIG 2> /dev/null)"
    export PARENT_COMPARTMENT_NAME="$(oci iam compartment get --compartment-id $PARENT_COMPARTMENT_OCID | jq '."data"."name"')"
    SERVICE_PRINCIPAL_NAME="$(oci iam user get --user-id $SERVICE_PRINCIPAL_OCID | jq '."data"."name"')"
    TENANT_NAME="$(oci iam tenancy get --tenancy-id $TENANT_OCID | jq '."data"."name"')"
    
    if [ -z $SERVICE_PRINCIPAL_NAME ]; then
        echo -e "\n\e[31m\t⚠️ You are not logged in to OCI!"
        echo -e "\e[31m\t😥 Visit https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htmi and follow the instructions"
        ERRORS+=$'  oci cli is  not configured with end user credential.\n'
        exit
    fi

}

# Validate the Git installation and version
function validate_git(){
    echo -e "\n\e[34m»»» ✅ \e[96mValidating Git installation..."
    if [ ! "$(command -v git)" ]; then
        echo_missing_installation "git" "https://git-scm.com/book/en/v2/Getting-Started-Installing-Git"
        ERRORS+=$'  git not found.\n'
    else
        GIT_CURRENT_VERSION=$(git version | awk '{print $3}')
        if [ "$(compare_version "$GIT_CURRENT_VERSION" "$GIT_VERSION")" -eq 2 ]; then
            echo_wrong_version "git" "at least" "$GIT_VERSION" "https://git-scm.com/book/en/v2/Getting-Started-Installing-Git" "$GIT_CURRENT_VERSION"
            ERRORS+=$'  git version is incompatible.\n'
        fi
    fi

    if ! git config init.defaultBranch | grep "main" >/dev/null ; then
        echo "  git default branch must be configured as main."
        echo "  See the instructions at https://github.com/terraform-google-modules/terraform-example-foundation/blob/master/docs/TROUBLESHOOTING.md#default-branch-setting ."
        ERRORS+=$'  git default branch must be configured as main.\n'
    fi
}

# Validate some utility tools that the environment must have before running the other checkers
function validate_utils(){
    echo -e "\n\e[34m»»» ✅ \e[96mValidating required utility tools..."
    if [ ! "$(command -v jq)" ]; then
        echo_missing_installation "jq" "https://stedolan.github.io/jq/download/"
        ERRORS+=$'  jq not found.\n'
    fi
}


function main(){
    BOOTSTRAP_DIR="$(find "$(cd ..; pwd)" -name "0.bootstrap" 2>/dev/null)"
    ENV_FILE="$(echo $BOOTSTRAP_DIR)/.env"
    BOOTSTRAP_SCRIPT="$(echo $BOOTSTRAP_DIR)/bootstrap.sh"
    OCI_CONFIG="$(echo $HOME/.oci/config)"

    validate_env_file

    validate_utils

    if [ -n "$ERRORS" ]; then
        echo -e "\e[31m   ⚠️ Some requirements are missing:"
        echo "$ERRORS"
        exit 1
    fi

    validate_terraform

    validate_oci_cli

    if [[ ! "$ERRORS" == *"az"* ]]; then
        validate_oci_configuration
    fi
    
    # validate_git

    echo "......................................."
    if [ -z "$ERRORS" ]; then
        echo -e "\n\e[34m»»» 🥳 No errors found."
        echo -e "\n\e[34m»»» 🚩 Validation successful!\e[0m"
    else
        echo -e "\e[31m»»» 💥 Validation failed!"
        echo -e "\e[31m»»» 💥 Errors found:"
        echo -r "$ERRORS\e[0m"
    fi

    echo ""
    echo ""
    echo -e "\n\e[34m🔨 \e[96mOCI details from logged on user \e[0m"
    echo -e "\e[34m\t• \e[96mTenant:                        \e[33m$TENANT_NAME\e[0m"
    echo -e "\e[34m\t• \e[96mParent Compartment Name:       \e[33m$PARENT_COMPARTMENT_NAME\e[0m"
    echo -e "\e[34m\t• \e[96mmUser:                         \e[33m$SERVICE_PRINCIPAL_NAME\e[0m"
    echo -e "\e[34m\t• \e[96mRegion:                        \e[33m$REGION\e[0m\n"
    echo -e "\n\e[34m»»» 📝 \e[96mNow you can start the bootstrap process using - $BOOTSTRAP_SCRIPT\e[0m"
    
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
