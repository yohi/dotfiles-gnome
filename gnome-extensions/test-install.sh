#!/bin/bash

# Simple test script for extension installation
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if required commands are available
check_dependencies() {
    local missing_deps=()
    local required_commands=("curl" "unzip" "python3" "glib-compile-schemas" "gnome-extensions" "gnome-shell")

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}[ERROR]${NC} 以下の必要なコマンドが見つかりません:"
        for dep in "${missing_deps[@]}"; do
            echo -e "  - $dep"
        done
        echo ""
        echo "これらのコマンドをインストールしてから再度実行してください。"
        exit 1
    fi

    echo -e "${GREEN}[INFO]${NC} すべての依存関係が確認できました"
}

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Compile schemas for extension
compile_extension_schemas() {
    local extension_uuid="$1"
    local extension_dir="$HOME/.local/share/gnome-shell/extensions/$extension_uuid"
    local schemas_dir="$extension_dir/schemas"

    if [ -d "$schemas_dir" ]; then
        log "$extension_uuid のスキーマをコンパイル中..."
        if ls "$schemas_dir"/*.gschema.xml 1> /dev/null 2>&1; then
            if glib-compile-schemas "$schemas_dir" 2>/dev/null; then
                success "$extension_uuid のスキーマをコンパイルしました"
                return 0
            else
                warning "$extension_uuid のスキーマコンパイルに失敗しました"
                return 1
            fi
        fi
    fi
    return 0
}

# Install extension manually
install_extension_manually() {
    local extension_uuid="$1"
    local extension_name="$2"

    log "$extension_name ($extension_uuid) を手動インストール中..."

    local temp_dir=$(mktemp -d)
    local gnome_version=$(gnome-shell --version | cut -d' ' -f3 | cut -d'.' -f1,2)

    # Get extension info from API
    local api_url="https://extensions.gnome.org/extension-info/?uuid=${extension_uuid}&shell_version=${gnome_version}"

    if curl -s "$api_url" | grep -q "download_url"; then
        local download_url=$(curl -s "$api_url" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data['download_url'])
except:
    sys.exit(1)
")

        if [ -n "$download_url" ]; then
            log "$extension_name のダウンロード中..."
            if curl -L "https://extensions.gnome.org$download_url" -o "$temp_dir/extension.zip"; then
                local install_dir="$HOME/.local/share/gnome-shell/extensions/$extension_uuid"
                mkdir -p "$install_dir"

                if unzip -q "$temp_dir/extension.zip" -d "$install_dir"; then
                    success "$extension_name のインストールが完了しました"
                    # Compile schemas
                    compile_extension_schemas "$extension_uuid"
                    rm -rf "$temp_dir"
                    return 0
                else
                    error "$extension_name の解凍に失敗しました"
                fi
            else
                error "$extension_name のダウンロードに失敗しました"
            fi
        fi
    fi

    rm -rf "$temp_dir"
    warning "$extension_name のインストールに失敗しました"
    return 1
}

echo "🧪 GNOME Extensions インストールテスト"
echo "====================================="

# Check dependencies before proceeding
check_dependencies

# Test extensions
declare -a test_extensions=(
    "bluetooth-battery@michalw.github.com|Bluetooth Battery Indicator"
    "bluetooth-quick-connect@bjarosze.gmail.com|Bluetooth Quick Connect"
    "tweaks-system-menu@extensions.gnome-shell.fifi.org|Tweaks & Extensions in System Menu"
    "search-light@icedman.github.com|Search Light"
)

for extension_info in "${test_extensions[@]}"; do
    IFS='|' read -r extension_uuid extension_name <<< "$extension_info"

    # Check if already installed
    if gnome-extensions list | grep -q "$extension_uuid"; then
        success "$extension_name は既にインストールされています"
    else
        # Install the extension
        if install_extension_manually "$extension_uuid" "$extension_name"; then
            success "$extension_name のインストールが完了しました"
        else
            error "$extension_name のインストールに失敗しました"
        fi
    fi

    # Try to enable
    sleep 1
    if gnome-extensions enable "$extension_uuid" 2>/dev/null; then
        success "$extension_name を有効化しました"
    else
        warning "$extension_name の有効化に失敗しました（GNOME Shell再起動が必要かもしれません）"
    fi
done

log "インストールテストが完了しました"
log "GNOME Shellの再起動をお勧めします: Alt + F2 → 'r' → Enter"

echo ""
success "🎉 テスト完了！"
echo ""
echo "💡 注意："
echo "  - GNOME Shellを再起動してください"
echo "  - 拡張機能が正常に動作することを確認してください"
echo "  - 問題がなければログアウト/再ログインしてください"
