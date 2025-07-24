# VNC Subdomain 故障排除指南

## 常見問題及解決方案

### 1. WebSocket 連接失敗

**症狀**: 瀏覽器控制台顯示 WebSocket 連接錯誤

**解決方案**:
```bash
# 檢查 WebSocket 端點是否可訪問
curl -I http://your-subdomain.com/websockify

# 檢查 Nginx 配置
docker-compose -f docker-compose.subdomain.yml exec nginx-proxy nginx -t

# 查看 Nginx 日誌
docker-compose -f docker-compose.subdomain.yml logs nginx-proxy
```

**常見原因**:
- Nginx 配置中缺少 WebSocket 升級頭
- 防火牆阻擋 WebSocket 連接
- SSL 證書問題

### 2. CORS 錯誤

**症狀**: 瀏覽器控制台顯示 CORS 錯誤

**解決方案**:
```nginx
# 在 Nginx 配置中添加 CORS 頭
add_header Access-Control-Allow-Origin "*";
add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization";
```

### 3. SSL 證書問題

**症狀**: 瀏覽器顯示 SSL 證書錯誤

**解決方案**:
```bash
# 檢查 SSL 證書狀態
docker-compose -f docker-compose.subdomain.yml exec nginx-proxy openssl s_client -connect localhost:443 -servername your-subdomain.com

# 重新申請證書
docker-compose -f docker-compose.subdomain.yml run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --email your-email@example.com --agree-tos --no-eff-email -d your-subdomain.com

# 重新加載 Nginx
docker-compose -f docker-compose.subdomain.yml exec nginx-proxy nginx -s reload
```

### 4. 頁面顯示空白或損壞

**症狀**: 頁面加載但顯示空白或元素錯位

**解決方案**:
```bash
# 檢查 noVNC 服務狀態
docker-compose -f docker-compose.subdomain.yml logs vnc-base

# 檢查靜態文件是否正確提供
curl -I http://your-subdomain.com/core/rfb.js

# 重新構建容器
docker-compose -f docker-compose.subdomain.yml down
docker-compose -f docker-compose.subdomain.yml build --no-cache
docker-compose -f docker-compose.subdomain.yml up -d
```

### 5. 連接超時

**症狀**: 連接建立後立即斷開或超時

**解決方案**:
```nginx
# 增加 Nginx 超時設置
proxy_connect_timeout 7d;
proxy_send_timeout 7d;
proxy_read_timeout 7d;
```

### 6. 性能問題

**症狀**: VNC 響應緩慢或卡頓

**解決方案**:
```bash
# 檢查系統資源使用
docker stats

# 增加容器資源限制
docker-compose -f docker-compose.subdomain.yml up -d --scale vnc-base=1 --memory=2g --cpus=1.0

# 優化 Nginx 緩衝設置
proxy_buffering off;
proxy_request_buffering off;
```

## 診斷工具

### 1. 網絡連接測試
```bash
# 測試端口可達性
telnet your-subdomain.com 443
telnet your-subdomain.com 80

# 測試 WebSocket 連接
wscat -c wss://your-subdomain.com/websockify
```

### 2. SSL 診斷
```bash
# 檢查 SSL 配置
openssl s_client -connect your-subdomain.com:443 -servername your-subdomain.com

# 檢查證書鏈
openssl x509 -in /path/to/certificate.crt -text -noout
```

### 3. 瀏覽器開發者工具
```javascript
// 在瀏覽器控制台中測試 WebSocket 連接
const ws = new WebSocket('wss://your-subdomain.com/websockify');
ws.onopen = () => console.log('WebSocket connected');
ws.onerror = (e) => console.error('WebSocket error:', e);
ws.onclose = () => console.log('WebSocket closed');
```

## 日誌分析

### 1. Nginx 日誌
```bash
# 查看訪問日誌
docker-compose -f docker-compose.subdomain.yml exec nginx-proxy tail -f /var/log/nginx/access.log

# 查看錯誤日誌
docker-compose -f docker-compose.subdomain.yml exec nginx-proxy tail -f /var/log/nginx/error.log
```

### 2. VNC 日誌
```bash
# 查看 VNC 服務日誌
docker-compose -f docker-compose.subdomain.yml logs -f vnc-base

# 查看 noVNC 日誌
docker-compose -f docker-compose.subdomain.yml exec vnc-base tail -f /var/log/novnc.log
```

### 3. SSL 證書日誌
```bash
# 查看 Certbot 日誌
docker-compose -f docker-compose.subdomain.yml logs certbot
```

## 性能優化

### 1. Nginx 優化
```nginx
# 啟用 gzip 壓縮
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

# 優化緩存
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 2. VNC 優化
```bash
# 調整 VNC 編碼設置
x11vnc -display :1 -nopw -listen localhost -xkb -ncache 10 -ncache_cr -rfbport 5900 -forever -shared -permitfiletransfer -tightfilexfer
```

### 3. 系統優化
```bash
# 增加系統文件描述符限制
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# 優化內核參數
echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" >> /etc/sysctl.conf
sysctl -p
```

## 安全檢查清單

### 1. 防火牆配置
```bash
# 只開放必要端口
ufw allow 80/tcp
ufw allow 443/tcp
ufw deny 6080/tcp  # 直接 VNC 端口
ufw deny 5900/tcp  # 直接 VNC 端口
```

### 2. SSL 安全設置
```nginx
# 強制 HTTPS
if ($scheme != "https") {
    return 301 https://$server_name$request_uri;
}

# 安全頭設置
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
```

### 3. 訪問控制
```nginx
# 基本認證
auth_basic "Restricted Access";
auth_basic_user_file /etc/nginx/.htpasswd;

# IP 白名單
allow 192.168.1.0/24;
deny all;
```

## 常見錯誤代碼

| 錯誤代碼 | 含義 | 解決方案 |
|----------|------|----------|
| 101 | WebSocket 協議切換失敗 | 檢查 Nginx WebSocket 配置 |
| 1006 | 連接異常關閉 | 檢查網絡連接和防火牆 |
| 1002 | 協議錯誤 | 檢查 SSL 證書和協議版本 |
| 1000 | 正常關閉 | 檢查客戶端連接邏輯 |

## 聯繫支持

如果以上解決方案無法解決問題，請提供以下信息：

1. 錯誤日誌
2. 瀏覽器控制台輸出
3. 網絡連接測試結果
4. 系統環境信息
5. 配置文件內容 