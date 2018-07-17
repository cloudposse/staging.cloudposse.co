FROM cloudposse/terraform-root-modules:0.4.5 as terraform-root-modules

FROM cloudposse/geodesic:0.11.6

ENV DOCKER_IMAGE="cloudposse/staging.cloudposse.co"
ENV DOCKER_TAG="latest"

ENV BANNER="staging.cloudposse.co"

# Default AWS Profile name
ENV AWS_DEFAULT_PROFILE="cpco-staging-admin"

# AWS Region for the cluster
ENV AWS_REGION="us-west-2"

# Terraform State Bucket
ENV TF_BUCKET="cpco-staging-terraform-state"
ENV TF_BUCKET_REGION="us-west-2"
ENV TF_DYNAMODB_TABLE="cpco-staging-terraform-state-lock"

# Terraform Vars
ENV TF_VAR_domain_name=staging.cloudposse.co
ENV TF_VAR_namespace=cpco
ENV TF_VAR_stage=staging

ENV TF_VAR_REDIS_INSTANCE_TYPE=cache.r3.large

# chamber KMS config
ENV CHAMBER_KMS_KEY_ALIAS="alias/cpco-staging-chamber"

# Copy root modules
COPY --from=terraform-root-modules /aws/ /conf/

# Place configuration in 'conf/' directory
COPY conf/ /conf/

# Filesystem entry for tfstate
RUN s3 fstab '${TF_BUCKET}' '/' '/secrets/tf'

# kops config
ENV KUBERNETES_VERSION="1.9.6"
ENV KOPS_CLUSTER_NAME="us-west-2.staging.cloudposse.co"
ENV KOPS_DNS_ZONE=${KOPS_CLUSTER_NAME}
ENV KOPS_STATE_STORE="s3://cpco-staging-kops-state"
ENV KOPS_STATE_STORE_REGION="us-west-2"
ENV KOPS_AVAILABILITY_ZONES="us-west-2a,us-west-2b,us-west-2c"
ENV KOPS_BASTION_PUBLIC_NAME="bastion"
ENV BASTION_MACHINE_TYPE="t2.medium"
ENV MASTER_MACHINE_TYPE="m4.large"
ENV NODE_MACHINE_TYPE="m4.large"
ENV NODE_MAX_SIZE="4"
ENV NODE_MIN_SIZE="4"

# Generate kops manifest
RUN build-kops-manifest

WORKDIR /conf/