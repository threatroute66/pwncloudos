# PWNCLOUDOS Docker Image - GUI-enabled with VNC
# Multi-stage build for optimized image size

# Stage 1: Builder - for compiling tools
FROM debian:bookworm AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cargo \
    rustc \
    ca-certificates \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install newer Go version (1.23) from official source
RUN wget -q https://go.dev/dl/go1.23.5.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz && \
    rm go1.23.5.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

# Build Go-based tools
WORKDIR /build

# CloudFox
RUN git clone https://github.com/BishopFox/cloudfox.git && \
    cd cloudfox && \
    go build -o /opt/multi_cloud_tools/cloudfox

# S3Scanner
RUN git clone https://github.com/sa7mon/S3Scanner.git && \
    cd S3Scanner && \
    go build -o /opt/multi_cloud_tools/s3scanner

# Stage 2: Final image
FROM debian:bookworm-slim

# Build arguments for customization
ARG VNC_PASSWORD=omvia
ARG DISPLAY=:1
ARG VNC_PORT=5901
ARG NOVNC_PORT=6080

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=${DISPLAY} \
    VNC_PORT=${VNC_PORT} \
    NOVNC_PORT=${NOVNC_PORT} \
    USER=omvia \
    HOME=/home/omvia\
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Create user with passwordless sudo
RUN useradd -m -s /bin/zsh -G sudo omvia && \
    echo "omvia:omvia" | chpasswd && \
    mkdir -p /etc/sudoers.d && \
    echo "omvia ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/omvia && \
    chmod 0440 /etc/sudoers.d/omvia

# Install base system packages and desktop environment
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Base system
    sudo locales ca-certificates wget curl git vim nano \
    # Lightweight desktop environment (XFCE optimized)
    xfce4 xfce4-terminal xfce4-goodies \
    dbus-x11 x11-xserver-utils \
    # VNC server and noVNC for browser access
    tigervnc-standalone-server tigervnc-common \
    novnc websockify \
    # Window manager essentials
    gtk2-engines-murrine gtk2-engines-pixbuf \
    # Fonts
    fonts-liberation fonts-dejavu \
    # Shells
    zsh zsh-autosuggestions zsh-syntax-highlighting \
    # Browsers
    chromium firefox-esr \
    # Network tools
    net-tools iputils-ping dnsutils netcat-traditional nmap curl wget \
    # Development tools
    python3 python3-pip python3-venv python3-pycryptodome pipx \
    build-essential git golang-go \
    # Cloud SDKs dependencies
    apt-transport-https gnupg lsb-release software-properties-common \
    # Additional utilities
    jq unzip zip p7zip-full \
    tmux screen htop \
    # Screenshot tool
    flameshot \
    # Web proxy tools
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# Install PowerShell
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget apt-transport-https software-properties-common && \
    wget -q "https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb" && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell && \
    rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    apt-get update && apt-get install -y google-cloud-cli && \
    rm -rf /var/lib/apt/lists/*

# Create tool directories
RUN mkdir -p /opt/{aws_tools,azure_tools,gcp_tools,multi_cloud_tools,ps_tools,code_scanning,cracking_tools} && \
    chown -R omvia:omvia /opt

# Install Python-based tools via pipx (as pwncloudos user)
USER omvia
WORKDIR /home/omvia

# Ensure pipx is properly initialized
RUN pipx ensurepath

# Install Python tools
RUN pipx install azure-cli && \
    pipx install impacket && \
    pipx install pacu && \
    pipx install principalmapper && \
    pipx install prowler && \
    pipx install scoutsuite && \
    pipx install trufflehog

# AWS Tools
RUN git clone https://github.com/dievus/AWeSomeUserFinder /opt/aws_tools/AWeSomeUserFinder && \
    git clone https://github.com/shabarkin/aws-enumerator /opt/aws_tools/aws_enumerator && \
    git clone https://github.com/Rezonate-io/github-oidc-checker /opt/aws_tools/github-oidc-checker && \
    git clone https://github.com/WithSecureLabs/IAMGraph /opt/aws_tools/IAMGraph && \
    git clone https://github.com/WeAreCloudar/s3-account-search /opt/aws_tools/s3_account_search

# Azure Tools
RUN git clone https://github.com/yuyudhn/AzSubEnum /opt/azure_tools/AzSubEnum && \
    git clone https://github.com/BloodHoundAD/AzureHound /opt/azure_tools/azure_hound && \
    git clone https://github.com/joswr1ght/basicblobfinder /opt/azure_tools/basicblobfinder && \
    git clone https://github.com/gremwell/o365enum /opt/azure_tools/o365enum && \
    git clone https://github.com/0xZDH/o365spray /opt/azure_tools/o365spray && \
    git clone https://github.com/dievus/Oh365UserFinder /opt/azure_tools/Oh365UserFinder && \
    git clone https://github.com/0xZDH/Omnispray /opt/azure_tools/Omnispray && \
    git clone https://github.com/dirkjanm/ROADtools /opt/azure_tools/roadrecon && \
    git clone https://github.com/Malcrove/SeamlessPass /opt/azure_tools/seamlesspass

# GCP Tools
RUN git clone https://github.com/pwnedlabs/automated-cloud-misconfiguration-testing /opt/gcp_tools/gcp-misconfig && \
    git clone https://github.com/egre55/gcp-permissions-checker /opt/gcp_tools/gcp-permissions-checker && \
    git clone https://github.com/google/gcp_scanner /opt/gcp_tools/gcp_scanner && \
    git clone https://github.com/pwnedlabs/google-workspace-enum /opt/gcp_tools/google-workspace-enum && \
    git clone https://github.com/hac01/iam-policy-visualize /opt/gcp_tools/iam-policy-visualize && \
    git clone https://github.com/helviojunior/sprayshark /opt/gcp_tools/sprayshark && \
    git clone https://github.com/urbanadventurer/username-anarchy /opt/gcp_tools/username-anarchy

# Multi-Cloud Tools
RUN git clone https://github.com/turbot/steampipe /opt/multi_cloud_tools/steampipe

# PowerShell Tools
RUN git clone https://github.com/Gerenios/AADInternals /opt/ps_tools/AADInternals && \
    git clone https://github.com/dafthack/GraphRunner /opt/ps_tools/GraphRunner && \
    git clone https://github.com/dafthack/MFASweep /opt/ps_tools/MFASweep && \
    git clone https://github.com/f-bader/TokenTacticsV2 /opt/ps_tools/TokenTacticsV2 && \
    git clone https://github.com/PowerShellMafia/PowerSploit /opt/ps_tools/PowerSploit

# Code Scanning Tools
RUN git clone https://github.com/awslabs/git-secrets /opt/code_scanning/git-secrets

# Install git-secrets
RUN cd /opt/code_scanning/git-secrets && \
    sudo make install

# Install tool-specific Python dependencies
RUN cd /opt/aws_tools/IAMGraph && pip3 install --user -r requirements.txt 2>/dev/null || true && \
    cd /opt/azure_tools/roadrecon && pip3 install --user -r requirements.txt 2>/dev/null || true && \
    cd /opt/gcp_tools/gcp_scanner && pip3 install --user -r requirements.txt 2>/dev/null || true

# Copy built tools from builder stage
USER root
COPY --from=builder /opt/multi_cloud_tools/cloudfox /opt/multi_cloud_tools/cloudfox
COPY --from=builder /opt/multi_cloud_tools/s3scanner /opt/multi_cloud_tools/s3scanner
RUN chmod +x /opt/multi_cloud_tools/cloudfox /opt/multi_cloud_tools/s3scanner

# Install Steampipe
RUN sudo /bin/sh -c "$(curl -fsSL https://steampipe.io/install/steampipe.sh)"

# Install Powerpipe
RUN sudo /bin/sh -c "$(curl -fsSL https://powerpipe.io/install/powerpipe.sh)"

# Install HashCat (from official repo)
RUN apt-get update && apt-get install -y hashcat && rm -rf /var/lib/apt/lists/*

# Install John the Ripper dependencies and build
RUN apt-get update && apt-get install -y libssl-dev && rm -rf /var/lib/apt/lists/* && \
    git clone https://github.com/openwall/john /opt/cracking_tools/john && \
    cd /opt/cracking_tools/john/src && \
    ./configure && make -s clean && make -sj4 && \
    ln -s /opt/cracking_tools/john/run/john /usr/local/bin/john

# Install ffuf (fuzzing tool)
RUN export GOBIN=/usr/local/bin && go install github.com/ffuf/ffuf/v2@latest

# Set ownership of opt directories
RUN chown -R omvia:omvia /opt/*

# Switch back to omvia user
USER omvia

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Copy configuration files from the repo
COPY --chown=omvia:omvia docs/configs/shell/zsh/user/.zshrc /home/omvia/.zshrc

# Copy PowerShell profile
RUN mkdir -p /home/omvia/.config/powershell
COPY --chown=omvia:omvia docs/configs/shell/powershell/user/Microsoft.PowerShell_profile.ps1 /home/omvia/.config/powershell/Microsoft.PowerShell_profile.ps1

# Copy brand logo for wallpaper
RUN sudo mkdir -p /usr/share/pwncloudos/brand
COPY ./logo.png /usr/share/pwncloudos/brand/logo.png

# Extract XFCE configuration
COPY --chown=omvia:omvia docs/configs/xfce/pwncloudos-xfce4-profile-pack.tar.gz /tmp/
RUN cd /tmp && \
    tar xzf pwncloudos-xfce4-profile-pack.tar.gz && \
    mkdir -p /home/omvia/.config/xfce4/xfconf/xfce-perchannel-xml && \
    mkdir -p /home/omvia/.local/share/applications && \
    cp pwncloudos-xfce4-profile/*.xml /home/omvia/.config/xfce4/xfconf/xfce-perchannel-xml/ && \
    cp -r pwncloudos-xfce4-profile/custom-launchers/* /home/omvia/.local/share/applications/ && \
    sudo chown -R omvia:omvia /home/omvia/.config /home/omvia/.local && \
    rm -rf /tmp/pwncloudos-xfce4-profile /tmp/pwncloudos-xfce4-profile-pack.tar.gz

# Create VNC directory and set VNC password
RUN mkdir -p /home/omvia/.vnc

# Switch to root for VNC setup
USER root

# Create startup script for VNC
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/vnc-startup.sh /usr/local/bin/vnc-startup.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/vnc-startup.sh

# Expose VNC and noVNC ports
EXPOSE ${VNC_PORT} ${NOVNC_PORT}

# Set working directory
WORKDIR /home/omvia

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD nc -z localhost ${VNC_PORT} || exit 1

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/usr/local/bin/vnc-startup.sh"]
