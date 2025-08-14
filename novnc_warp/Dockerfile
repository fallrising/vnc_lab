# novnc_warp - Warp Terminal with VNC Access
# Based on novnc_base with Warp terminal integration

ARG BASE_IMAGE=debian:bullseye-slim
FROM ${BASE_IMAGE}

# Build arguments for multi-platform support
ARG TARGETARCH
ARG TARGETOS

USER root

# Install additional dependencies for Warp terminal
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    fonts-noto \
    fonts-noto-cjk \
    fonts-powerline \
    libssl-dev \
    pkg-config \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install terminal (Warp for AMD64, Alacritty for ARM64)
RUN case ${TARGETARCH} in \
        amd64) \
            echo "Installing Warp terminal for AMD64..." && \
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
            export PATH="/root/.cargo/bin:${PATH}" && \
            curl -fsSL https://releases.warp.dev/install.sh | sh && \
            ln -s /usr/local/bin/warp /usr/bin/warp ;; \
        arm64) \
            echo "Installing xterm terminal for ARM64 (Warp not available)..." && \
            apt-get update && apt-get install -y xterm && \
            ln -s /usr/bin/xterm /usr/bin/warp && \
            rm -rf /var/lib/apt/lists/* ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac

# Create user for better security
RUN useradd -m -s /bin/bash warp \
    && mkdir -p /home/warp/workspace \
    && chown -R warp:warp /home/warp

# Create Warp config directory for persistence
RUN mkdir -p /home/warp/.config/warp \
    && chown -R warp:warp /home/warp/.config

# Create supervisor config directory and config for Warp terminal
RUN mkdir -p /app/conf.d && \
    echo '[program:warp]' > /app/conf.d/warp.conf && \
    echo 'command=/usr/bin/warp --display=:0' >> /app/conf.d/warp.conf && \
    echo 'environment=DISPLAY=":0",HOME="/home/warp",PATH="/root/.cargo/bin:${PATH}"' >> /app/conf.d/warp.conf && \
    echo 'autorestart=true' >> /app/conf.d/warp.conf && \
    echo 'user=warp' >> /app/conf.d/warp.conf && \
    echo 'redirect_stderr=true' >> /app/conf.d/warp.conf && \
    echo 'stdout_logfile=/var/log/warp.log' >> /app/conf.d/warp.conf && \
    echo 'stderr_logfile=/var/log/warp_error.log' >> /app/conf.d/warp.conf && \
    echo 'priority=100' >> /app/conf.d/warp.conf

# Create log files
RUN touch /var/log/warp.log /var/log/warp_error.log \
    && chown warp:warp /var/log/warp.log /var/log/warp_error.log

# Create volume for Warp config persistence
VOLUME ["/home/warp/.config/warp", "/home/warp/workspace"]

# Expose ports (only for local access - use reverse proxy for external access)
EXPOSE 6080 5900

# Security: Set proper permissions
RUN chmod 755 /home/warp \
    && chmod 700 /home/warp/.config 