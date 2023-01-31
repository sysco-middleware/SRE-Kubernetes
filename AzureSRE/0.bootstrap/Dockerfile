FROM oraclelinux:8

# Install Azure CLI
WORKDIR /root/
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc
RUN dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
RUN echo -e '[azure-cli]\n\
name=Azure CLI\n\
baseurl=https://packages.microsoft.com/yumrepos/azure-cli\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://packages.microsoft.com/keys/microsoft.asc' | tee /etc/yum.repos.d/azure-cli.repo
RUN dnf install -y azure-cli

# Install Terraform
RUN dnf install -y yum-utils
RUN dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
RUN dnf install -y terraform

# Install jq

RUN dnf install -y jq