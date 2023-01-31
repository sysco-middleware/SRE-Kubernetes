# Terraform Google Cloud Bootstrap & CI/CD

- [Terraform Google Cloud Bootstrap \& CI/CD](#terraform-google-cloud-bootstrap--cicd)
  - [Introduction](#introduction)
  - [pre-requisites](#pre-requisites)
  - [Configuration](#configuration)
  - [Usage](#usage)

## Introduction

The purpose of this repo is to help bootstrap a Google Project, creating all the required Google Cloud resources & permissions to start using Terraform for managing Google Project.

There's four main outcomes of this repo:

- Bootstrap of backend state in Google Bucket for all Terraform to use.
- Deployment (and redeployment) set of shared, management resources.
- Creation of service principals with role assignments in Google Cloud. (Yet to be completed)
- Initial configuration of GitHub Actions.(Yet to be completed)

## pre-requisites

- Bash
- Terraform 1.3.0+
- gcloud sdk
- Authenticated connection to Google Cloud, using gcloud sdk

  ```bash
  gcloud auth login
  ```

- GitHub Repo
- A GitHub PAT token (full scope) for the relevant repo

> **NOTE:**
>
> `validate-requirements.sh` script validates the pre-requisites. 

## Configuration

Before running any of the scripts, the configuration and input variables need to be set. This is done in an `.env` file, and this file is read and parsed by scripts

Copy `.env.sample` to `.env` and set values for all variables:

- `tf_var_management_Location` - Google Cloud region to deploy all resources into.
- `tf_var_management_ProjectID` - The shared project for all hub resources, including the bucket.
- `tf_var_management_BucketName` - Name of the storage bucket to hold Terraform state (default: `tfstate`).
- `tf_var_resource_prefix` - A prefix added to all resources, pick your project name or other prefix to give the resources unique names.

> NOTE:
>
> The bootstrap script, `bootstrap.sh` updates the Terraform backend variables defined in `backend.tf` based on the variables defined in the `.env` file.

## Usage

clone the repo

  ```bash
  git clone -b develop git@github.com:sysco-middleware/SRE-Kubernetes.git
  ```

You can use the `Dockerfile`to build a container with all required softwares installed or install all the softwares on your system manually

If using `Dockerfile`, you can mount the working directory to container and work on it

```bash
# Build the image
cd SRE-Kubernetes/0.bootstrap
docker build -t gcloud-sre .

# Run docker container with `SRE-Kubernetes` directory mounted as volume
cd SRE-Kubernetes
docker run --rm -it -v "$PWD:/root/gcloud-sre" --name gcloud-sre gcloud-sre
```

Authenticate to use Google Cloud CLI

```Bash
cd ./gcloud-sre/0.bootstrap/scripts
bash gcloud-login.sh -t <TENANT_ID> -s <SUBSCRIPTION_ID> -u <SERVICE_PRINCIPAL_ID> -p <SERVICE_PRINCIPAL_SECRET>
```

Validate the pre-requisites

```bash
cd ./gcloud-sre/0.bootstrap/scripts
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