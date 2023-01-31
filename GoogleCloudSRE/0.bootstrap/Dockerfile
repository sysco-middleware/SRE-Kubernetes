FROM oraclelinux:8

# Install gcloud CLI
WORKDIR /root/
RUN echo -e '[google-cloud-cli]\n\
name=Google Cloud CLI\n\
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64\n\
enabled=1\n\
gpgcheck=1\n\
repo_gpgcheck=0\n\
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' | tee /etc/yum.repos.d/google-cloud-sdk.repo
RUN dnf install -y google-cloud-sdk

# Install Terraform
RUN dnf install -y yum-utils
RUN dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
RUN dnf install -y terraform

# Install jq
RUN dnf install -y jq
