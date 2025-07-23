# Build the image first
docker build -t desktop-container .

# Debug
docker exec desktop-container /opt/scripts/debug.sh

# CF tunnel
docker run --rm -d \
  --name desktop-container \
  -p 127.0.0.1:6080:6080 \
  -p 127.0.0.1:7681:7681 \
  -v firefox-profile:/home/firefox-profile \
  -e VNC_PASSWORD="MySecurePassword123" \
  -e TTYD_PASSWORD="MyTerminalPassword123" \
  -e TUNNEL_TOKEN="YOUR_TOKEN" \
  u80250docker/novnc_firefox_llm_cli

# Read Env From files
docker run --rm -d \
  --name desktop-container \
  -p 127.0.0.1:6080:6080 \
  -p 127.0.0.1:7681:7681 \
  -v firefox-profile:/home/firefox-profile \
  --env-file .env \
  u80250docker/novnc_firefox_llm_cli

# Basic secure run (localhost only, with persistence)
docker run -d \
  --name desktop-container \
  -p 127.0.0.1:6080:6080 \
  -p 127.0.0.1:7681:7681 \
  -v firefox-profile:/home/firefox-profile \
  -e VNC_PASSWORD="your_secure_vnc_password" \
  -e TTYD_PASSWORD="your_secure_terminal_password" \
  --restart unless-stopped \
  u80250docker/novnc_firefox_llm_cli

# Advanced secure run with custom settings
docker run -d \
  --name desktop-container \
  -p 127.0.0.1:6080:6080 \
  -p 127.0.0.1:7681:7681 \
  -v firefox-profile:/home/firefox-profile \
  -v $(pwd)/downloads:/home/downloads \
  -e VNC_PASSWORD="MySecureVNC2025!" \
  -e TTYD_PASSWORD="MySecureTTYD2025!" \
  -e TUNNEL_TOKEN="your_cloudflared_token_here" \
  --memory="2g" \
  --cpus="1.5" \
  --restart unless-stopped \
  --security-opt no-new-privileges:true \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/log \
  --tmpfs /home/firefox-profile/.cache \
  u80250docker/novnc_firefox_llm_cli

# Production-ready secure run with additional hardening
docker run -d \
  --name production-desktop \
  -p 127.0.0.1:6080:6080 \
  -p 127.0.0.1:7681:7681 \
  -v firefox-profile:/home/firefox-profile \
  -v $(pwd)/workspace:/workspace \
  -e VNC_PASSWORD="$(openssl rand -base64 32)" \
  -e TTYD_PASSWORD="$(openssl rand -base64 32)" \
  --memory="4g" \
  --cpus="2.0" \
  --restart unless-stopped \
  --security-opt no-new-privileges:true \
  --security-opt seccomp=unconfined \
  --cap-drop ALL \
  --cap-add SETUID \
  --cap-add SETGID \
  --read-only \
  --tmpfs /tmp:size=1g \
  --tmpfs /var/log:size=100m \
  --tmpfs /home/firefox-profile/.cache:size=500m \
  --user root \
  --network bridge \
  u80250docker/novnc_firefox_llm_cli

# Quick start with random passwords (development)
docker run --rm -d \
  --name dev-desktop \
  -p 127.0.0.1:6080:6080 \
  -p 127.0.0.1:7681:7681 \
  -v firefox-profile:/home/firefox-profile \
  u80250docker/novnc_firefox_llm_cli

# Check container logs to see the generated passwords
docker logs desktop-container

# Access URLs after container starts:
# noVNC Desktop: http://localhost:6080
# Web Terminal: http://localhost:7681

# Useful management commands:
# View logs: docker logs desktop-container
# Shell access: docker exec -it desktop-container bash
# Stop: docker stop desktop-container
# Remove: docker rm desktop-container
# View passwords: docker logs desktop-container | grep "Password:"
