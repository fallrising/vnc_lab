# VNC Lab - Remote Desktop Laboratory

A Docker-based remote desktop laboratory project that provides multiple VNC desktop environments with web browser access and AI tool integration.

## Project Overview

VNC Lab is a containerized remote desktop solution based on noVNC technology, allowing users to access complete Linux desktop environments through web browsers. The project includes three different container configurations to meet various usage scenarios.

## Project Structure

```
vnc_lab/
├── novnc_base/           # Basic VNC desktop environment
│   └── Dockerfile       # Basic container configuration
├── novnc_llm_cli/       # VNC environment with AI CLI tools integration
│   ├── Dockerfile       # Main container configuration
│   ├── Dockerfile.add_validation  # Container config with validation features
│   └── README.md        # Detailed usage instructions
├── novnc_tool/          # Tool environment based on theasp/novnc
│   └── Dockerfile       # Tool container configuration
└── README.md           # Project documentation
```

## Container Descriptions

### 1. novnc_base - Basic Desktop Environment

**Features:**
- Lightweight system based on Debian Bullseye
- Integrated noVNC 1.4.0 and x11vnc
- Pre-installed Firefox ESR browser
- Openbox window manager
- Supervisor process management support

**Use Cases:**
- Basic remote desktop access
- Lightweight web browsing environment
- Learning and testing environments

### 2. novnc_llm_cli - AI Tools Integration Environment

**Features:**
- All features from the basic environment
- Integrated AI CLI tools:
  - Google Gemini CLI (`@google/gemini-cli`)
  - Anthropic Claude Code (`@anthropic-ai/claude-code`)
  - Atlassian CLI (`acli`)
- Integrated ttyd web terminal
- Cloudflare Tunnel remote access support
- Enhanced monitoring and debugging capabilities
- Firefox profile persistence

**Use Cases:**
- AI development and testing
- Remote development environments
- Work environments requiring AI tool assistance

### 3. novnc_tool - Enhanced Tools Environment

**Features:**
- Based on `theasp/novnc` image
- Integrated Node.js and npm
- Includes AI CLI tools
- ttyd and cloudflared support
- Multi-service management with Supervisor

**Use Cases:**
- Node.js development environments
- Tool integration testing
- Multi-service management requirements

## Quick Start

### Requirements

- Docker 20.10+
- At least 2GB available memory
- Network connection (for downloading images and tools)

### Basic Usage

1. **Build base image:**
```bash
cd novnc_base
docker build -t vnc-base .
```

2. **Run base container:**
```bash
docker run -d \
  --name vnc-base \
  -p 6080:6080 \
  -p 5900:5900 \
  vnc-base
```

3. **Access desktop:**
   - Open browser and visit: `http://localhost:6080`
   - Or use VNC client to connect: `localhost:5900`

### AI Tools Environment Usage

1. **Build AI tools image:**
```bash
cd novnc_llm_cli
docker build -t vnc-llm-cli .
```

2. **Run container with password protection:**
```bash
docker run -d \
  --name vnc-llm \
  -p 6080:6080 \
  -p 7681:7681 \
  -v firefox-profile:/home/firefox-profile \
  -e VNC_PASSWORD="your_vnc_password" \
  -e TTYD_PASSWORD="your_terminal_password" \
  vnc-llm-cli
```

3. **Access services:**
   - Desktop environment: `http://localhost:6080`
   - Web terminal: `http://localhost:7681`

## Advanced Configuration

### Environment Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `VNC_PASSWORD` | VNC connection password | `vnc123` |
| `TTYD_PASSWORD` | Web terminal password | `MyTerminalPassword123` |
| `TUNNEL_TOKEN` | Cloudflare Tunnel token | None |

### Port Descriptions

| Port | Service | Description |
|------|---------|-------------|
| 6080 | noVNC | Web VNC client |
| 5900 | x11vnc | Traditional VNC service |
| 7681 | ttyd | Web terminal service |

### Data Persistence

- **Firefox Profile:** Use Docker volume `firefox-profile` to persist browser configuration
- **Working Directory:** Mount local directories to containers for file sharing

## Security Recommendations

1. **Password Settings:**
   - Use strong passwords to replace default passwords
   - Change passwords regularly
   - Avoid hardcoding passwords in code

2. **Network Access:**
   - Default binding to localhost, limiting local access
   - Use Cloudflare Tunnel for secure remote access
   - Avoid direct exposure to public networks

3. **Container Security:**
   - Use `--security-opt no-new-privileges`
   - Limit container resource usage
   - Regularly update base images

## Troubleshooting

### Common Issues

1. **Container startup failure:**
```bash
# View container logs
docker logs <container_name>

# Enter container for debugging
docker exec -it <container_name> /opt/scripts/debug.sh
```

2. **VNC connection issues:**
   - Check if ports are correctly mapped
   - Confirm firewall settings
   - Verify password configuration

3. **Performance issues:**
   - Increase container memory limits
   - Check system resource usage
   - Optimize display resolution settings

### Debug Tools

The project provides a debug script `/opt/scripts/debug.sh` that can:
- Check service status
- View port listening status
- Analyze log files
- Verify network connections

## Development Guide

### Custom Images

1. **Modify Dockerfile:**
   - Add required software packages
   - Configure custom startup scripts
   - Adjust system settings

2. **Build and test:**
```bash
docker build -t custom-vnc .
docker run --rm -it -p 6080:6080 custom-vnc
```

### Contributing

1. Fork the project
2. Create a feature branch
3. Commit changes
4. Create a Pull Request

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Changelog

### v1.0.0
- Initial release
- Support for basic VNC desktop environment
- AI CLI tools integration
- Web terminal support

## Contact

For questions or suggestions, please contact us through:
- Submit an Issue
- Send email
- Join discussions

---

**Note:** This project is for learning and research purposes only. Please comply with relevant laws and regulations and platform usage terms. 