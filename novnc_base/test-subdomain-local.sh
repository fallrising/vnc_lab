#!/bin/bash

# 本地子域名測試腳本
# 使用 /etc/hosts 模擬子域名訪問

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 測試域名
TEST_DOMAIN="vnc-test.local"
TEST_URL="http://$TEST_DOMAIN:6080"

# 檢查 hosts 文件配置
check_hosts_config() {
    print_status "檢查 /etc/hosts 配置..."
    
    if grep -q "$TEST_DOMAIN" /etc/hosts; then
        print_success "找到 $TEST_DOMAIN 在 /etc/hosts 中"
        return 0
    else
        print_error "$TEST_DOMAIN 未在 /etc/hosts 中找到"
        print_status "請運行: echo '127.0.0.1 $TEST_DOMAIN' | sudo tee -a /etc/hosts"
        return 1
    fi
}

# 測試 localhost 訪問
test_localhost() {
    print_status "測試 localhost 訪問..."
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:6080 | grep -q "200"; then
        print_success "Localhost 訪問正常"
        return 0
    else
        print_error "Localhost 訪問失敗"
        return 1
    fi
}

# 測試子域名訪問
test_subdomain() {
    print_status "測試子域名訪問: $TEST_URL"
    
    if curl -s -o /dev/null -w "%{http_code}" "$TEST_URL" | grep -q "200"; then
        print_success "子域名訪問正常"
        return 0
    else
        print_error "子域名訪問失敗"
        return 1
    fi
}

# 測試 WebSocket URL 解析
test_websocket_url() {
    print_status "測試 WebSocket URL 解析..."
    
    # 獲取 HTML 內容
    HTML_CONTENT=$(curl -s "$TEST_URL")
    
    # 檢查是否包含動態 WebSocket URL 解析代碼
    if echo "$HTML_CONTENT" | grep -q "Dynamic WebSocket URL resolution"; then
        print_success "檢測到動態 WebSocket URL 解析代碼"
        return 0
    else
        print_warning "未檢測到動態 WebSocket URL 解析代碼"
        return 0  # 不是錯誤，可能是使用默認 noVNC
    fi
}

# 測試 DNS 解析
test_dns_resolution() {
    print_status "測試 DNS 解析..."
    
    if nslookup "$TEST_DOMAIN" 2>/dev/null | grep -q "127.0.0.1"; then
        print_success "DNS 解析正常: $TEST_DOMAIN -> 127.0.0.1"
        return 0
    else
        print_warning "DNS 解析可能不正常，但 hosts 文件應該生效"
        return 0
    fi
}

# 創建測試 HTML 文件
create_test_html() {
    print_status "創建測試 HTML 文件..."
    
    cat > /tmp/subdomain-test.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>子域名測試</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .test-result { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .success { background-color: #d4edda; color: #155724; }
        .error { background-color: #f8d7da; color: #721c24; }
        .info { background-color: #d1ecf1; color: #0c5460; }
    </style>
</head>
<body>
    <h1>VNC 子域名測試</h1>
    <p>測試域名: <strong>$TEST_DOMAIN</strong></p>
    
    <div class="test-result info">
        <h3>測試結果</h3>
        <p>如果看到這個頁面，說明子域名訪問正常工作。</p>
    </div>
    
    <div class="test-result info">
        <h3>WebSocket URL 測試</h3>
        <p>預期的 WebSocket URL: <code>ws://$TEST_DOMAIN:6080/websockify</code></p>
        <p>實際的 WebSocket URL 將由 noVNC 動態解析。</p>
    </div>
    
    <div class="test-result info">
        <h3>下一步</h3>
        <p>1. 訪問 <a href="$TEST_URL" target="_blank">$TEST_URL</a> 查看 VNC 界面</p>
        <p>2. 檢查瀏覽器控制台是否有 WebSocket 連接錯誤</p>
        <p>3. 如果一切正常，說明子域名配置成功</p>
    </div>
    
    <script>
        // 模擬 WebSocket URL 解析
        function getWebSocketURL() {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const host = window.location.host;
            const path = window.location.pathname.replace(/\/$/, '');
            return \`\${protocol}//\${host}\${path}/websockify\`;
        }
        
        const wsUrl = getWebSocketURL();
        console.log('計算的 WebSocket URL:', wsUrl);
        
        // 顯示結果
        document.getElementById('ws-url').textContent = wsUrl;
    </script>
    
    <div class="test-result success">
        <h3>WebSocket URL 計算結果</h3>
        <p>計算的 WebSocket URL: <code id="ws-url"></code></p>
    </div>
</body>
</html>
EOF
    
    print_success "測試 HTML 文件創建在: /tmp/subdomain-test.html"
    print_status "您可以在瀏覽器中打開這個文件來查看測試結果"
}

# 顯示測試信息
show_test_info() {
    echo
    print_status "測試配置信息:"
    echo "  測試域名: $TEST_DOMAIN"
    echo "  測試 URL: $TEST_URL"
    echo "  本地端口: 6080"
    echo "  Hosts 文件: /etc/hosts"
    echo
    print_status "測試步驟:"
    echo "  1. 確保 VNC 容器正在運行"
    echo "  2. 訪問 $TEST_URL"
    echo "  3. 檢查瀏覽器控制台"
    echo "  4. 測試 VNC 連接"
    echo
}

# 主測試函數
main() {
    print_status "開始本地子域名測試..."
    echo
    
    local tests_passed=0
    local tests_total=0
    
    # 運行所有測試
    check_hosts_config && ((tests_passed++))
    ((tests_total++))
    
    test_dns_resolution && ((tests_passed++))
    ((tests_total++))
    
    test_localhost && ((tests_passed++))
    ((tests_total++))
    
    test_subdomain && ((tests_passed++))
    ((tests_total++))
    
    test_websocket_url && ((tests_passed++))
    ((tests_total++))
    
    create_test_html
    ((tests_total++))
    
    echo
    print_status "測試結果: $tests_passed/$tests_total 測試通過"
    
    if [[ $tests_passed -eq $((tests_total - 1)) ]]; then
        print_success "所有測試通過！子域名配置成功！"
        echo
        show_test_info
        print_status "現在您可以:"
        print_status "1. 在瀏覽器中訪問: $TEST_URL"
        print_status "2. 測試 VNC 連接是否正常工作"
        print_status "3. 檢查 WebSocket 連接是否成功"
        echo
        print_status "如果一切正常，說明您的配置已經準備好用於 Cloudflare Tunnel！"
    else
        print_error "部分測試失敗，請檢查配置。"
        exit 1
    fi
}

# 清理函數
cleanup() {
    print_status "清理測試環境..."
    # 可以添加清理代碼
}

# 處理信號
trap cleanup EXIT

# 運行主函數
main "$@" 