#!/bin/bash

# 清理測試配置腳本
# 移除 /etc/hosts 中的測試域名

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

# 檢查是否為 root 用戶
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此腳本需要 root 權限來修改 /etc/hosts"
        print_status "請使用: sudo $0"
        exit 1
    fi
}

# 備份 hosts 文件
backup_hosts() {
    print_status "備份 /etc/hosts 文件..."
    
    if [[ ! -f /etc/hosts.backup ]]; then
        cp /etc/hosts /etc/hosts.backup
        print_success "已備份到 /etc/hosts.backup"
    else
        print_warning "/etc/hosts.backup 已存在，跳過備份"
    fi
}

# 移除測試域名
remove_test_domain() {
    print_status "移除測試域名: $TEST_DOMAIN"
    
    if grep -q "$TEST_DOMAIN" /etc/hosts; then
        # 創建臨時文件
        grep -v "$TEST_DOMAIN" /etc/hosts > /tmp/hosts.tmp
        mv /tmp/hosts.tmp /etc/hosts
        print_success "已移除 $TEST_DOMAIN"
    else
        print_warning "$TEST_DOMAIN 未在 /etc/hosts 中找到"
    fi
}

# 驗證清理結果
verify_cleanup() {
    print_status "驗證清理結果..."
    
    if grep -q "$TEST_DOMAIN" /etc/hosts; then
        print_error "清理失敗，$TEST_DOMAIN 仍然存在於 /etc/hosts 中"
        return 1
    else
        print_success "清理成功，$TEST_DOMAIN 已從 /etc/hosts 中移除"
        return 0
    fi
}

# 顯示幫助信息
show_help() {
    echo "用法: $0 [選項]"
    echo
    echo "選項:"
    echo "  -h, --help     顯示此幫助信息"
    echo "  -r, --restore  從備份恢復 /etc/hosts"
    echo "  -b, --backup   僅備份 /etc/hosts"
    echo
    echo "示例:"
    echo "  sudo $0          # 清理測試配置"
    echo "  sudo $0 -r       # 從備份恢復"
    echo "  sudo $0 -b       # 僅備份"
}

# 從備份恢復
restore_hosts() {
    print_status "從備份恢復 /etc/hosts..."
    
    if [[ -f /etc/hosts.backup ]]; then
        cp /etc/hosts.backup /etc/hosts
        print_success "已從 /etc/hosts.backup 恢復"
    else
        print_error "備份文件 /etc/hosts.backup 不存在"
        exit 1
    fi
}

# 僅備份
backup_only() {
    print_status "僅備份 /etc/hosts..."
    backup_hosts
    print_success "備份完成"
}

# 主函數
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -r|--restore)
            check_root
            restore_hosts
            exit 0
            ;;
        -b|--backup)
            check_root
            backup_only
            exit 0
            ;;
        "")
            # 默認清理操作
            check_root
            backup_hosts
            remove_test_domain
            verify_cleanup
            print_success "清理完成！"
            ;;
        *)
            print_error "未知選項: $1"
            show_help
            exit 1
            ;;
    esac
}

# 運行主函數
main "$@" 