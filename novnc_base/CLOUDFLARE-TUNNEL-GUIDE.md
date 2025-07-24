# Cloudflare Tunnel VNC 部署指南

## 概述

本指南將幫助您使用 Cloudflare Tunnel Zero Trust 部署 VNC 容器，實現安全的遠程桌面訪問。

## 特性

✅ **動態配置**: 支持環境變量配置  
✅ **子域名兼容**: 自動適配任何子域名  
✅ **WebSocket 支持**: 完整的 WebSocket 連接支持  
✅ **無 HTTPS 要求**: 專為 Cloudflare Tunnel 優化  
✅ **通用設計**: 同時支持 localhost 和子域名訪問  

## 快速開始

### 1. 構建並啟動容器

```bash
# 構建鏡像
docker build -t vnc-base:latest .

# 啟動容器（支持 Cloudflare Tunnel）
./run.sh -H 0.0.0.0 -d

# 或使用環境變量
CLOUDFLARE_TUNNEL=1 ./run.sh -H 0.0.0.0 -d
```

### 2. 驗證容器狀態

```bash
# 運行兼容性測試
./test-cloudflare.sh

# 檢查容器狀態
docker logs vnc-base

# 測試本地訪問
curl -I http://localhost:6080
```

### 3. 配置 Cloudflare Tunnel

#### 在 Cloudflare Zero Trust Dashboard 中：

1. **創建 Tunnel**:
   - 進入 Zero Trust Dashboard
   - 選擇 "Access" → "Tunnels"
   - 點擊 "Create a tunnel"

2. **配置路由**:
   - 添加公共主機名（例如：`vnc.yourdomain.com`）
   - 服務類型選擇：`HTTP`
   - URL 設置為：`http://localhost:6080`

3. **下載並運行 cloudflared**:
   ```bash
   # 下載 cloudflared
   wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
   chmod +x cloudflared-linux-amd64
   
   # 運行 tunnel
   ./cloudflared-linux-amd64 tunnel run your-tunnel-name
   ```

### 4. 訪問 VNC

- **本地訪問**: `http://localhost:6080`
- **Cloudflare Tunnel**: `https://vnc.yourdomain.com`

## 配置選項

### 環境變量

| 變量 | 描述 | 默認值 | 示例 |
|------|------|--------|------|
| `VNC_HOST` | VNC 主機綁定 | `0.0.0.0` | `0.0.0.0` |
| `VNC_PORT` | VNC Web 端口 | `6080` | `6080` |
| `VNC_BACKEND_HOST` | VNC 後端主機 | `localhost` | `localhost` |
| `VNC_BACKEND_PORT` | VNC 後端端口 | `5900` | `5900` |
| `CLOUDFLARE_TUNNEL` | 啟用 Cloudflare Tunnel 模式 | 未設置 | `1` |

### 命令行選項

```bash
# 基本 localhost 訪問
./run.sh

# Cloudflare Tunnel 模式
./run.sh -H 0.0.0.0

# 自定義端口
./run.sh -p 8080 -P 5901 -H 0.0.0.0

# 掛載卷
./run.sh -v /path/to/data:/home/shared -H 0.0.0.0

# 資源限制
./run.sh -m 2g -c 1.5 -H 0.0.0.0
```

### 環境文件

創建 `.env` 文件：
```bash
VNC_HOST=0.0.0.0
VNC_PORT=6080
VNC_BACKEND_HOST=localhost
VNC_BACKEND_PORT=5900
CLOUDFLARE_TUNNEL=1
```

使用環境文件：
```bash
./run.sh -e .env
```

## Docker Compose 部署

### 使用 Docker Compose

```bash
# 使用 Cloudflare Tunnel 配置
docker-compose -f docker-compose.cloudflare.yml up -d

# 查看日誌
docker-compose -f docker-compose.cloudflare.yml logs -f
```

### 自定義 Docker Compose

```yaml
version: '3.8'

services:
  vnc-base:
    build: .
    container_name: vnc-base-cloudflare
    restart: unless-stopped
    ports:
      - "0.0.0.0:6080:6080"
      - "0.0.0.0:5900:5900"
    environment:
      - VNC_HOST=0.0.0.0
      - VNC_PORT=6080
      - VNC_BACKEND_HOST=localhost
      - VNC_BACKEND_PORT=5900
      - CLOUDFLARE_TUNNEL=1
    volumes:
      - vnc-data:/home/shared
    networks:
      - vnc-network

volumes:
  vnc-data:

networks:
  vnc-network:
    driver: bridge
```

## 故障排除

### 常見問題

#### 1. 容器無法啟動

```bash
# 檢查日誌
docker logs vnc-base

# 檢查端口衝突
lsof -i :6080

# 重新構建鏡像
docker build -t vnc-base:latest .
```

#### 2. WebSocket 連接失敗

```bash
# 測試 WebSocket 端點
curl -I http://localhost:6080/websockify

# 檢查瀏覽器控制台錯誤
# 確保 Cloudflare Tunnel 配置正確
```

#### 3. 子域名訪問問題

```bash
# 運行兼容性測試
./test-cloudflare.sh

# 檢查環境變量
docker exec vnc-base printenv | grep VNC

# 驗證 HTML 內容
curl http://localhost:6080 | grep "Dynamic WebSocket"
```

### 診斷命令

```bash
# 檢查容器狀態
docker ps | grep vnc-base

# 檢查進程
docker exec vnc-base ps aux | grep -E "(x11vnc|websockify)"

# 檢查環境變量
docker exec vnc-base printenv | grep VNC

# 測試連接
curl -I http://localhost:6080
```

## 安全考慮

### Cloudflare Zero Trust 安全

1. **身份驗證**: 使用 Cloudflare Zero Trust 進行身份驗證
2. **網絡隔離**: 容器僅通過 Cloudflare Tunnel 訪問
3. **審計日誌**: Cloudflare 提供訪問日誌和分析
4. **無直接暴露**: 無需將端口暴露到互聯網

### 最佳實踐

1. **使用強密碼**: 在 Cloudflare Zero Trust 中設置強密碼
2. **限制訪問**: 配置適當的訪問策略
3. **定期更新**: 保持容器和 Cloudflare Tunnel 更新
4. **監控日誌**: 定期檢查訪問日誌

## 性能優化

### Cloudflare Tunnel 優化

1. **邊緣優化**: 利用 Cloudflare 邊緣網絡
2. **WebSocket 優化**: 正確的 WebSocket 配置
3. **壓縮**: 在 Cloudflare Tunnel 設置中啟用壓縮

### VNC 優化

1. **編碼設置**: 使用適當的 VNC 編碼
2. **壓縮級別**: 配置壓縮以獲得更好的性能
3. **幀率**: 根據網絡條件優化幀率

## 示例配置

### 生產環境配置

```bash
# 創建生產環境配置
cat > .env.production << EOF
VNC_HOST=0.0.0.0
VNC_PORT=6080
VNC_BACKEND_HOST=localhost
VNC_BACKEND_PORT=5900
CLOUDFLARE_TUNNEL=1
EOF

# 啟動生產環境
./run.sh -e .env.production -m 4g -c 2.0 --no-rm
```

### 開發環境配置

```bash
# 創建開發環境配置
cat > .env.development << EOF
VNC_HOST=127.0.0.1
VNC_PORT=6080
VNC_BACKEND_HOST=localhost
VNC_BACKEND_PORT=5900
EOF

# 啟動開發環境
./run.sh -e .env.development -v /path/to/project:/home/shared
```

## 支持

如果遇到問題：

1. 運行 `./test-cloudflare.sh` 進行診斷
2. 檢查 `TROUBLESHOOTING-SUBDOMAIN.md` 獲取詳細故障排除信息
3. 查看容器日誌：`docker logs vnc-base`
4. 檢查 Cloudflare Tunnel 狀態

## 更新日誌

- **v1.0.0**: 初始版本，支持 Cloudflare Tunnel
- **v1.1.0**: 添加動態配置支持
- **v1.2.0**: 改進 WebSocket URL 解析
- **v1.3.0**: 添加兼容性測試腳本 