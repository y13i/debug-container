FROM denoland/deno:2.5.5 AS deno
FROM hashicorp/terraform:1.13.4 AS terraform
FROM valkey/valkey:9.0.0 AS valkey
FROM ghcr.io/mccutchen/go-httpbin:2.19.0 AS go-httpbin

FROM public.ecr.aws/lts/ubuntu:24.04_stable AS main

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "I am running on ${BUILDPLATFORM}, building for ${TARGETPLATFORM}"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt -y update && \
  apt -y upgrade && \
  apt -y install \
  apt-transport-https \
  bat \
  build-essential \
  ca-certificates \
  curl \
  dnsutils \
  eza \
  fd-find \
  file \
  fzf \
  git \
  git-delta \
  gnupg \
  htop \
  hyperfine \
  iperf3 \
  iproute2 \
  iputils-ping \
  jq \
  less \
  lnav \
  mandoc \
  mysql-client \
  net-tools \
  netcat-openbsd \
  openssh-client \
  postgresql-client \
  procps \
  redis-tools \
  ripgrep \
  screen \
  sl \
  strace \
  sudo \
  tzdata \
  unzip \
  vim \
  zip \
  zoxide \
  zsh && \
  apt -y clean && \
  ln -s /usr/games/sl /usr/bin/sl && \
  batcat --version && \
  curl --version && \
  dig -v && \
  delta --version && \
  eza --version && \
  fdfind --version && \
  fzf --version && \
  nslookup -version && \
  git --version && \
  htop --version && \
  hyperfine --version && \
  iperf3 --version && \
  ip -V && \
  ping -V && \
  jq --version && \
  less --version && \
  lnav --version && \
  mysql --version && \
  ifconfig -V && \
  nc -h && \
  ssh -V && \
  psql --version && \
  redis-cli --version && \
  rg --version && \
  screen --version && \
  strace --version && \
  sudo --version && \
  unzip -v && \
  vim --version && \
  zip -v && \
  zoxide --version && \
  zsh --version

# Install Deno
COPY --from=deno /usr/bin/deno /usr/bin/deno
RUN deno --version

# Install Terraform
COPY --from=terraform /bin/terraform /usr/bin/terraform
RUN terraform -version

# Install valkey-cli
COPY --from=valkey /usr/local/bin/valkey-cli /usr/bin/valkey-cli
RUN valkey-cli --version

# Install go-httpbin
COPY --from=go-httpbin /bin/go-httpbin /usr/bin/go-httpbin

# Install AWS CLI
ARG AWSCLI_ARCH
RUN case "${TARGETPLATFORM}" in \
  "linux/arm64") AWSCLI_ARCH="aarch64" ;; \
  "linux/amd64") AWSCLI_ARCH="x86_64" ;; \
  esac && \
  curl -L "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}.zip" -o "/tmp/awscliv2.zip" && \
  unzip -q "/tmp/awscliv2.zip" -d /tmp && \
  /tmp/aws/install && \
  rm -rf "/tmp/aws" "/tmp/awscliv2.zip" && \
  aws --version

# Install Google Cloud SDK
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  apt -y update && apt -y install google-cloud-cli && \
  apt -y clean && \
  gcloud --version

# Install kubectl
RUN curl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/${TARGETPLATFORM}/kubectl" -o /usr/bin/kubectl && \
  chmod +x /usr/bin/kubectl && \
  kubectl version --client

# Install K9s
ARG K9S_ARCH
RUN case "${TARGETPLATFORM}" in \
  "linux/arm64") K9S_ARCH="linux_arm64" ;; \
  "linux/amd64") K9S_ARCH="linux_amd64" ;; \
  esac && \
  curl -L "https://github.com/derailed/k9s/releases/download/v0.50.9/k9s_${K9S_ARCH}.deb" -o "/tmp/k9s.deb" && \
  dpkg -i /tmp/k9s.deb && \
  rm -rf /tmp/k9s.deb && \
  k9s version

# Install kubectx
RUN git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
  ln -s /opt/kubectx/kubectx /usr/bin/kubectx && \
  ln -s /opt/kubectx/kubens /usr/bin/kubens

# Create non-root user
RUN useradd -m -s /bin/zsh -G sudo me && \
  echo 'me ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
  chsh -s /bin/zsh me

# Switch to non-root user
USER me
WORKDIR /home/me

# Setup zsh
RUN git clone https://github.com/y13i/.zsh.git /home/me/.zsh && \
  chmod +x /home/me/.zsh/install.sh && \
  /home/me/.zsh/install.sh
RUN mkdir -p ~/.oh-my-zsh/custom/completions && \
  chmod -R 755 ~/.oh-my-zsh/custom/completions && \
  ln -s /opt/kubectx/completion/_kubectx.zsh ~/.oh-my-zsh/custom/completions/_kubectx.zsh && \
  ln -s /opt/kubectx/completion/_kubens.zsh ~/.oh-my-zsh/custom/completions/_kubens.zsh

CMD ["/bin/zsh"]
