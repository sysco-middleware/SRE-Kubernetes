# Terraform Azure Bootstrap & CI/CD

The purpose of this repo is to help bootstrap a Azure subscription, creating all the required Azure resources & permissions to start using Terraform for managing Azure Subscription. 

There's four main outcomes of this repo:

- Bootstrap of backend state in Azure Storage for all Terraform to use.
- Deployment (and redeployment) set of shared, management resources.
- Creation of service principals with role assignments in Azure AD. (Yet to be completed)
- Initial configuration of GitHub Actions.(Yet to be completed)

## pre-requisites

- Bash
- Terraform 1.3.0+
- Azure CLI
- Authenticated connection to Azure, using Azure CLI
  ```bash
  az login --tenant <TENANT_ID>
  ```
- GitHub Repo
- A GitHub PAT token (full scope) for the relevant repo

> NOTE:
> 
> `validate-requirements.sh` script validates the pre-requisites.

## Usage

clone the repo
  ```bash
  git clone 
  ```

You can use the `Dockerfile`to build a container with all required softwares installed or install all the softwares on your system manually

If using `Dockerfile`, you can mount the working directory to container and work on it

```bash
docker build -t azure-sre .
docker run --rm -it -v "$PWD/AzureSRE:/root/AzureSRE" --name AzureSRE azure-sre
```

### Configuration

Before running any of the scripts, the configuration and input variables need to be set. This is done in an `.env` file, and this file is read and parsed by scripts

Copy `.env.sample` to `.env` and set values for all variables:

- `tf_var_management_Region` - Azure region to deploy all resources into.
- `tf_var_management_ResourceGroup` - The shared resource group for all hub resources, including the storage account.
- `tf_var_management_StorageAccountName` - The name of the storage account to hold Terraform state.
- `tf_var_management_ContainerName` - Name of the blob container to hold Terraform state (default: `tfstate`).
- `tf_var_resource_prefix` - A prefix added to all resources, pick your project name or other prefix to give the resources unique names.

> NOTE:
>
> The bootstrap script, `bootstrap.sh` updates the Terraform backend variables defined in `backend.tf` based on the variables defined in the `.env` file.


### Running the scripts

Validate the pre-requisites

```bash
cd ./AzureSRE/0.bootstrap/scripts
bash validate-requirements.sh -t <TENANT_ID> -s <SUBSCRIPTION_ID> -u <SERVICE_PRINCIPAL_ID> -p <SERVICE_PRINCIPAL_SECRET>
```

Bootstrap the environment

```bash
bash bootstrap.sh -t <TENANT_ID> -s <SUBSCRIPTION_ID> -u <SERVICE_PRINCIPAL_ID> -p <SERVICE_PRINCIPAL_SECRET>
```

Deploy the resources

```bash
bash deploy.sh -t <TENANT_ID> -s <SUBSCRIPTION_ID> -u <SERVICE_PRINCIPAL_ID> -p <SERVICE_PRINCIPAL_SECRET>
```
