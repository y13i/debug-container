FROM denoland/deno:2.4.5 AS deno
FROM hashicorp/terraform:1.13.1 AS terraform
FROM valkey/valkey:8.1.3 AS valkey

FROM public.ecr.aws/lts/ubuntu:24.04_stable AS main

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "I am running on ${BUILDPLATFORM}, building for ${TARGETPLATFORM}"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt -y update && \
  apt -y upgrade && \
  apt -y install \
  apt-transport-https \
  ca-certificates \
  curl \
  dnsutils \
  git \
  gnupg \
  htop \
  iperf3 \
  iproute2 \
  iputils-ping \
  jq \
  less \
  mandoc \
  mysql-client \
  net-tools \
  netcat-openbsd \
  openssh-client \
  postgresql-client \
  redis-tools \
  screen \
  sl \
  strace \
  sudo \
  tzdata \
  unzip \
  vim \
  zip && \
  apt -y clean && \
  ln -s /usr/games/sl /usr/bin/sl && \
  curl --version && \
  dig -v && \
  nslookup -version && \
  git --version && \
  htop --version && \
  iperf3 --version && \
  ip -V && \
  ping -V && \
  jq --version && \
  less --version && \
  mysql --version && \
  ifconfig -V && \
  nc -h && \
  ssh -V && \
  psql --version && \
  redis-cli --version && \
  screen --version && \
  strace --version && \
  sudo --version && \
  unzip -v && \
  vim --version && \
  zip -v

# Install Deno
COPY --from=deno /usr/bin/deno /usr/bin/deno
RUN deno --version

# Install Terraform
COPY --from=terraform /bin/terraform /usr/bin/terraform
RUN terraform -version

# Install valkey-cli
COPY --from=valkey /usr/local/bin/valkey-cli /usr/bin/valkey-cli
RUN valkey-cli --version

# Install AWS CLI
ARG AWSCLI_ARCH
RUN case "${TARGETPLATFORM}" in \
  "linux/arm64") AWSCLI_ARCH="aarch64" ;; \
  "linux/amd64") AWSCLI_ARCH="x86_64" ;; \
  esac && \
  curl -L "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}.zip" -o "/tmp/awscliv2.zip" && \
  unzip "/tmp/awscliv2.zip" -q -d /tmp && \
  /tmp/aws/install && \
  rm -rf "/tmp/aws" "/tmp/awscliv2.zip" && \
  aws --version

# Install Google Cloud SDK
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  apt -y update && apt -y install google-cloud-cli && \
  apt -y clean && \
  gcloud --version
