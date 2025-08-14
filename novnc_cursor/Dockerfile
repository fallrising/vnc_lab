# novnc_cursor - Cursor IDE with VNC Access
# Based on novnc_base with Cursor IDE integration

ARG BASE_IMAGE=debian:bullseye-slim
FROM ${BASE_IMAGE}

# Build arguments for multi-platform support
ARG TARGETARCH
ARG TARGETOS

USER root

# Install additional dependencies for Cursor IDE
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (required for Cursor IDE)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install IDE with architecture detection using TARGETARCH
RUN echo "Installing Cursor IDE for ${TARGETARCH}..." && \
    apt-get update && apt-get install -y libfuse2 libnss3 libatk-bridge2.0-0 libdrm2 libxcomposite1 libxdamage1 libxrandr2 libgbm1 libxkbcommon0 libxss1 libasound2 && \
    case ${TARGETARCH} in \
        amd64) \
            curl 'https://downloads.cursor.com/production/82a3a053262d453a3a053262d453a3a053262d453a3a053262d453a3a053262d453a3a053262d/linux/x64/Cursor-1.4.5-x64.AppImage' \
                -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
                -H 'accept-language: zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7' \
                -b 'IndrX2ZuSmZramJSX0NIYUZoRzRzUGZ0cENIVHpHNXk0VE0ya2ZiUkVzQU14X2Fub255bW91c1VzZXJJZCI%3D=ImQ4MTBjMGZiLWJlYTUtNDdjOC05MjJmLWVmODRhZmRkZjA2MSI=' \
                -H 'dnt: 1' \
                -H 'priority: u=0, i' \
                -H 'sec-ch-ua: "Not;A=Brand";v="99", "Google Chrome";v="139", "Chromium";v="139"' \
                -H 'sec-ch-ua-mobile: ?0' \
                -H 'sec-ch-ua-platform: "macOS"' \
                -H 'sec-fetch-dest: document' \
                -H 'sec-fetch-mode: navigate' \
                -H 'sec-fetch-site: none' \
                -H 'sec-fetch-user: ?1' \
                -H 'upgrade-insecure-requests: 1' \
                -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36' \
                -o cursor.AppImage ;; \
        arm64) \
            curl 'https://downloads.cursor.com/production/af58d92614edb1f72bdd756615d131bf8dfa5299/linux/arm64/Cursor-1.4.5-aarch64.AppImage' \
                -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
                -H 'accept-language: zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7' \
                -b 'IndrX2ZuSmZramJSX0NIYUZoRzRzUGZ0cENIVHpHNXk0VE0ya2ZiUkVzQU14X2Fub255bW91c1VzZXJJZCI%3D=ImQ4MTBjMGZiLWJlYTUtNDdjOC05MjJmLWVmODRhZmRkZjA2MSI=' \
                -H 'dnt: 1' \
                -H 'priority: u=0, i' \
                -H 'sec-ch-ua: "Not;A=Brand";v="99", "Google Chrome";v="139", "Chromium";v="139"' \
                -H 'sec-ch-ua-mobile: ?0' \
                -H 'sec-ch-ua-platform: "macOS"' \
                -H 'sec-fetch-dest: document' \
                -H 'sec-fetch-mode: navigate' \
                -H 'sec-fetch-site: none' \
                -H 'sec-fetch-user: ?1' \
                -H 'upgrade-insecure-requests: 1' \
                -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36' \
                -o cursor.AppImage ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    chmod +x cursor.AppImage && \
    mv cursor.AppImage /usr/local/bin/cursor && \
    rm -rf /var/lib/apt/lists/*

# Create user for better security
RUN useradd -m -s /bin/bash cursor \
    && mkdir -p /home/cursor/workspace \
    && chown -R cursor:cursor /home/cursor

# Create Cursor profile directory for persistence
RUN mkdir -p /home/cursor/.config/Cursor \
    && chown -R cursor:cursor /home/cursor/.config

# Create supervisor config directory and config for Cursor IDE
RUN mkdir -p /app/conf.d && \
    echo '[program:cursor]' > /app/conf.d/cursor.conf && \
    echo 'command=/usr/local/bin/cursor --no-sandbox --disable-gpu --display=:0' >> /app/conf.d/cursor.conf && \
    echo 'environment=DISPLAY=":0",HOME="/home/cursor"' >> /app/conf.d/cursor.conf && \
    echo 'autorestart=true' >> /app/conf.d/cursor.conf && \
    echo 'user=cursor' >> /app/conf.d/cursor.conf && \
    echo 'redirect_stderr=true' >> /app/conf.d/cursor.conf && \
    echo 'stdout_logfile=/var/log/cursor.log' >> /app/conf.d/cursor.conf && \
    echo 'stderr_logfile=/var/log/cursor_error.log' >> /app/conf.d/cursor.conf && \
    echo 'priority=100' >> /app/conf.d/cursor.conf

# Create log files
RUN touch /var/log/cursor.log /var/log/cursor_error.log \
    && chown cursor:cursor /var/log/cursor.log /var/log/cursor_error.log

# Create volume for Cursor profile persistence
VOLUME ["/home/cursor/.config/Cursor", "/home/cursor/workspace"]

# Expose ports (only for local access - use reverse proxy for external access)
EXPOSE 6080 5900

# Security: Set proper permissions
RUN chmod 755 /home/cursor \
    && chmod 700 /home/cursor/.config 