FROM denoland/deno:2.4.5 as deno
FROM hashicorp/terraform:1.13.1 as terraform
FROM valkey/valkey:8.1.3 as valkey

FROM public.ecr.aws/lts/ubuntu:24.04_stable

ENV DEBIAN_FRONTEND=noninteractive

RUN apt -y update && \
  apt -y upgrade && \
  apt -y install apt-transport-https ca-certificates curl dnsutils git gnupg htop iputils-ping jq less mandoc mysql-client net-tools openssh-client postgresql-client redis-tools screen sl snapd sudo tzdata unzip vim zip && \
  apt -y clean

# Install Deno
COPY --from=deno /usr/bin/deno /usr/bin/deno

# Install Terraform
COPY --from=terraform /bin/terraform /usr/bin/terraform

# Install valkey-cli
COPY --from=valkey /usr/local/bin/valkey-cli /usr/bin/valkey-cli

# Install AWS CLI
RUN snap install aws-cli --classic && \
  aws --version

# Install Google Cloud SDK
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  apt -y update && apt -y install google-cloud-cli && \
  apt -y clean
