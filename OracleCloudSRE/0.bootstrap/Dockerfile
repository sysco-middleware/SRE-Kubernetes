FROM oraclelinux:8

# Enable developer repo
RUN dnf install -y oraclelinux-developer-release-el8

# Install OCI-CLI
RUN dnf install -y python36-oci-cli
ENV OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING=True

# Install Terraform
RUN dnf install -y yum-utils
RUN dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
RUN dnf install -y terraform

# Install jq

RUN dnf install -y jq