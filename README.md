> ## ⚠️ 此 repository 已退役（2026-09-04）
>
> 內容已遷移至 [`newclear`](https://github.com/fallrising/newclear) 的 [`platform/fanzloud/docs/legacy-vnc_lab`](https://github.com/fallrising/newclear/tree/main/platform/fanzloud/docs/legacy-vnc_lab)。
>
> 本 repository 保留為**唯讀歷史存放地**——完整 git 歷史仍在此處,
> 但新的開發請至後繼者。

---

# VNC Lab - Remote Desktop Laboratory

A Docker-based remote desktop laboratory project that provides multiple VNC desktop environments with web browser access and AI tool integration.

## Project Overview

VNC Lab is a containerized remote desktop solution based on noVNC technology, allowing users to access complete Linux desktop environments through web browsers. The project includes three different container configurations to meet various usage scenarios.

## Project Structure

```
vnc_lab/
├── novnc_base/           # Basic VNC desktop environment
│   ├── Dockerfile       # Basic container configuration
│   ├── build.sh         # Build script
│   ├── run.sh           # Run script
│   ├── clean.sh         # Clean script
│   ├── test_base.sh     # Test script
│   └── README.md        # Detailed usage instructions
├── novnc_cursor/        # Cursor IDE VNC environment
│   ├── Dockerfile       # CPU version configuration
│   ├── Dockerfile.gpu   # GPU version configuration
│   ├── build.sh         # Build script with GPU support
│   ├── run.sh           # Run script with GPU support
│   ├── test_cursor.sh   # Test script with GPU support
│   └── README.md        # Detailed usage instructions
├── novnc_llm_cli/       # VNC environment with AI CLI tools integration
│   ├── Dockerfile       # Main container configuration
│   ├── Dockerfile.add_validation  # Container config with validation features
│   ├── build.sh         # Build script
│   ├── run.sh           # Run script
│   ├── test_llm.sh      # Test script for AI tools
│   └── README.md        # Detailed usage instructions
├── novnc_tool/          # Tool environment based on theasp/novnc
│   ├── Dockerfile       # Tool container configuration
│   ├── build.sh         # Build script
│   ├── run.sh           # Run script
│   ├── test_tool.sh     # Test script for development tools
│   └── README.md        # Detailed usage instructions
├── novnc_warp/          # Warp terminal VNC environment
│   ├── Dockerfile       # CPU version configuration
│   ├── Dockerfile.gpu   # GPU version configuration
│   ├── build.sh         # Build script with GPU support
│   ├── run.sh           # Run script with GPU support
│   ├── test_warp.sh     # Test script for Warp functionality
│   └── README.md        # Detailed usage instructions
├── manage.sh            # Unified management script for all containers
├── push_all.sh          # Push all images to Docker Hub
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
- Cloudflare Tunnel compatibility
- Subdomain support for dynamic access

**Use Cases:**
- Basic remote desktop access
- Lightweight web browsing environment
- Learning and testing environments
- Foundation for other specialized containers

### 2. novnc_cursor - Cursor IDE Environment

**Features:**
- All features from the basic environment
- Integrated Cursor IDE with AI capabilities
- AMD GPU acceleration support (optional)
- Enhanced graphics performance
- Secure local binding with reverse proxy support
- Persistent configuration and workspace storage

**Use Cases:**
- AI-assisted development
- Remote development environments
- GPU-accelerated coding
- Modern IDE experience through browser

### 3. novnc_llm_cli - AI Tools Integration Environment

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

### 4. novnc_tool - Enhanced Tools Environment

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

### 5. novnc_warp - Warp Terminal Environment

**Features:**
- All features from the basic environment
- Integrated Warp terminal with AI capabilities
- AMD GPU acceleration support (optional)
- Enhanced terminal experience
- AI-powered command assistance
- Persistent configuration and workspace storage

**Use Cases:**
- Modern terminal experience
- AI-assisted command line work
- GPU-accelerated terminal operations
- Remote terminal access through browser

## Quick Start

### Requirements

- Docker 20.10+
- At least 2GB available memory
- Network connection (for downloading images and tools)
- AMD GPU (optional, for GPU-accelerated containers)

### Build Order

Due to dependencies, build containers in this order:

1. **Build base image first:**
```bash
cd novnc_base
./build.sh
```

2. **Build specialized containers:**
```bash
# Cursor IDE (CPU version)
cd ../novnc_cursor
./build.sh

# Cursor IDE (GPU version - requires AMD GPU)
./build.sh --gpu

# AI Tools environment
cd ../novnc_llm_cli
./build.sh

# Tool environment
cd ../novnc_tool
./build.sh

# Warp terminal (CPU version)
cd ../novnc_warp
./build.sh

# Warp terminal (GPU version - requires AMD GPU)
./build.sh --gpu
```

### Basic Usage

#### 1. Base Environment
```bash
cd novnc_base
./run.sh
# Access: http://localhost:6080
```

#### 2. Cursor IDE Environment
```bash
cd novnc_cursor
# CPU version
./run.sh

# GPU version (if AMD GPU available)
./run.sh --gpu

# Access: http://localhost:6080
```

#### 3. AI Tools Environment
```bash
cd novnc_llm_cli
./run.sh
# Access: http://localhost:6080 (Desktop), http://localhost:7681 (Terminal)
```

#### 4. Tool Environment
```bash
cd novnc_tool
./run.sh
# Access: http://localhost:8080 (Desktop), http://localhost:7681 (Terminal)
```

#### 5. Warp Terminal Environment
```bash
cd novnc_warp
# CPU version
./run.sh

# GPU version (if AMD GPU available)
./run.sh --gpu

# Access: http://localhost:6080
```

### Unified Management

Use the root `manage.sh` script for unified management:

```bash
# Build all containers
./manage.sh build all

# Run specific container
./manage.sh run novnc_cursor

# Check status of all containers
./manage.sh status

# Clean all resources
./manage.sh clean all

### Testing

Each container has a dedicated test script:

```bash
# Test base environment
cd novnc_base && ./test_base.sh

# Test Cursor IDE (including GPU support)
cd novnc_cursor && ./test_cursor.sh --gpu

# Test AI tools environment
cd novnc_llm_cli && ./test_llm.sh --ai-tools

# Test development tools
cd novnc_tool && ./test_tool.sh --tools

# Test Warp terminal (including GPU support)
cd novnc_warp && ./test_warp.sh --gpu

### Pushing to Docker Hub

Push all images to u80250docker Docker Hub account:

```bash
# Push all images (latest tags only)
./push_all.sh --latest

# Push all images including GPU versions
./push_all.sh --gpu

# Push specific container with GPU support
./push_all.sh --cursor --gpu

# Dry run to see what would be pushed
./push_all.sh --dry-run

# Push specific version
./push_all.sh --version v1.0.0
```

Images will be available at: https://hub.docker.com/r/u80250docker
```

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