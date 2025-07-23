# Docker
FROM theasp/novnc:latest

USER root

# Update package list and install Firefox, Node.js, npm and dependencies
RUN apt-get update && apt-get install -y \
    firefox-esr \
    wget \
    curl \
    vim \
    htop \
    nodejs \
    npm \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd
RUN wget -O /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 \
    && chmod +x /usr/local/bin/ttyd

# Install cloudflared
RUN wget -O cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
    && dpkg -i cloudflared.deb \
    && rm cloudflared.deb

# Install CLI tools via npm
RUN npm install -g @google/gemini-cli @anthropic-ai/claude-code

# Install Atlassian CLI
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -nv -O- https://acli.atlassian.com/gpg/public-key.asc | gpg --dearmor -o /etc/apt/keyrings/acli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/acli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/acli-archive-keyring.gpg] https://acli.atlassian.com/linux/deb stable main" > /etc/apt/sources.list.d/acli.list && \
    apt-get update && \
    apt-get install -y acli && \
    rm -rf /var/lib/apt/lists/*

# Create the conf.d directory
RUN mkdir -p /app/conf.d

# Create Firefox profile directory for persistence
RUN mkdir -p /home/firefox-profile

# Create Firefox supervisor config file in /app/conf.d directory with profile persistence
RUN echo '[program:firefox]' > /app/conf.d/firefox.conf && \
    echo 'command=/usr/bin/firefox-esr --display=:0 --new-instance --profile /home/firefox-profile' >> /app/conf.d/firefox.conf && \
    echo 'environment=DISPLAY=":0"' >> /app/conf.d/firefox.conf && \
    echo 'autorestart=true' >> /app/conf.d/firefox.conf && \
    echo 'user=root' >> /app/conf.d/firefox.conf && \
    echo 'redirect_stderr=true' >> /app/conf.d/firefox.conf && \
    echo 'stdout_logfile=/var/log/firefox.log' >> /app/conf.d/firefox.conf && \
    echo 'stderr_logfile=/var/log/firefox_error.log' >> /app/conf.d/firefox.conf && \
    echo 'priority=100' >> /app/conf.d/firefox.conf

# Create ttyd supervisor config file in /app/conf.d directory (bind to localhost only)
RUN echo '[program:ttyd]' > /app/conf.d/ttyd.conf && \
    echo 'command=/usr/local/bin/ttyd -p 7681 -i 127.0.0.1 -W bash' >> /app/conf.d/ttyd.conf && \
    echo 'autorestart=true' >> /app/conf.d/ttyd.conf && \
    echo 'user=root' >> /app/conf.d/ttyd.conf && \
    echo 'redirect_stderr=true' >> /app/conf.d/ttyd.conf && \
    echo 'stdout_logfile=/var/log/ttyd.log' >> /app/conf.d/ttyd.conf && \
    echo 'stderr_logfile=/var/log/ttyd_error.log' >> /app/conf.d/ttyd.conf && \
    echo 'priority=200' >> /app/conf.d/ttyd.conf

# Create cloudflared supervisor config file
RUN echo '[program:cloudflared]' > /app/conf.d/cloudflared.conf && \
    echo 'command=/usr/local/bin/cloudflared tunnel run --token %(ENV_TUNNEL_TOKEN)s' >> /app/conf.d/cloudflared.conf && \
    echo 'autorestart=true' >> /app/conf.d/cloudflared.conf && \
    echo 'user=root' >> /app/conf.d/cloudflared.conf && \
    echo 'redirect_stderr=true' >> /app/conf.d/cloudflared.conf && \
    echo 'stdout_logfile=/var/log/cloudflared.log' >> /app/conf.d/cloudflared.conf && \
    echo 'stderr_logfile=/var/log/cloudflared_error.log' >> /app/conf.d/cloudflared.conf && \
    echo 'priority=50' >> /app/conf.d/cloudflared.conf

# Create log files
RUN touch /var/log/firefox.log /var/log/firefox_error.log /var/log/ttyd.log /var/log/ttyd_error.log /var/log/cloudflared.log /var/log/cloudflared_error.log

# Create volume for Firefox profile persistence
VOLUME ["/home/firefox-profile"]

# Expose ports (only for local access - cloudflared will handle external access)
EXPOSE 8080 7681
