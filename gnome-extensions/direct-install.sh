#!/bin/bash

# 🚀 GNOME Extensions 直接インストールスクリプト
# extensions.gnome.org API を直接使用して拡張機能をインストール

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 拡張機能ディレクトリ
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"

# ログ関数
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
title() { echo -e "${PURPLE}$1${NC}"; }

# 環境チェック
check_deps() {
    local deps=("curl" "unzip" "jq" "glib-compile-schemas")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "$dep が見つかりません"
            exit 1
        fi
    done
}

# 拡張機能をインストール
install_extension() {
    local uuid="$1"
    local name="$2"

    log "インストール中: $name"

    # 既にインストール済みかチェック
    local install_path="$EXTENSIONS_DIR/$uuid"
    if [ -d "$install_path" ]; then
        success "$name は既にインストール済み"
        return 0
    fi

    # GNOME Shell バージョン取得
    local gnome_ver=$(gnome-shell --version | grep -oP '\d+\.\d+')

    # API から拡張機能情報を取得
    local api_url="https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$gnome_ver"
    local metadata=$(curl -s "$api_url")

    # ダウンロードURL取得
    local download_url=$(echo "$metadata" | jq -r '.download_url // empty')

    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        # バージョン指定なしで再試行
        api_url="https://extensions.gnome.org/extension-info/?uuid=$uuid"
        metadata=$(curl -s "$api_url")
        download_url=$(echo "$metadata" | jq -r '.download_url // empty')
    fi

    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        error "$name のダウンロードURLが見つかりません"
        return 1
    fi

    # 一時ディレクトリ作成
    local temp_dir=$(mktemp -d)
    local zip_file="$temp_dir/extension.zip"

    # ダウンロード
    if curl -L --fail --silent "https://extensions.gnome.org$download_url" -o "$zip_file"; then
        # インストールディレクトリ作成
        mkdir -p "$install_path"

        # 解凍
        if unzip -q "$zip_file" -d "$install_path"; then
            # スキーマがある場合はコンパイル
            if [ -d "$install_path/schemas" ]; then
                glib-compile-schemas "$install_path/schemas" 2>/dev/null || true
            fi

            success "$name のインストールが完了"
            rm -rf "$temp_dir"
            return 0
        else
            error "$name の解凍に失敗"
        fi
    else
        error "$name のダウンロードに失敗"
    fi

    rm -rf "$temp_dir" "$install_path"
    return 1
}

# 拡張機能を有効化
enable_extension() {
    local uuid="$1"
    local name="$2"

    if gnome-extensions enable "$uuid" 2>/dev/null; then
        success "$name を有効化"
        return 0
    else
        warning "$name の有効化に失敗"
        return 1
    fi
}

# メイン処理
main() {
    echo
    title "🚀 GNOME Extensions 直接インストーラー"
    title "======================================"
    echo

    # 依存関係チェック
    check_deps

    # 拡張機能リスト（UUID:名前の形式）
    declare -A extensions=(
        ["bluetooth-battery@michalw.github.com"]="Bluetooth Battery Indicator"
        ["bluetooth-quick-connect@bjarosze.gmail.com"]="Bluetooth Quick Connect"
        ["Move_Clock@rmy.pobox.com"]="Move Clock"
        ["tweaks-system-menu@extensions.gnome-shell.fifi.org"]="Tweaks & Extensions in System Menu"
        ["BringOutSubmenuOfPowerOffLogoutButton@pratap.fastmail.fm"]="Bring Out Submenu Of Power Off/Logout Button"
        ["PrivacyMenu@stuarthayhurst"]="Privacy Menu"
        ["vertical-workspaces@G-dH.github.com"]="Vertical Workspaces"
        ["monitor@astraext.github.io"]="Astra Monitor"
        ["search-light@icedman.github.com"]="Search Light"
    )

    local total=${#extensions[@]}
    local installed=0
    local enabled=0
    local current=0

    # インストール処理
    title "📦 拡張機能をインストール中..."
    for uuid in "${!extensions[@]}"; do
        ((current++))
        local name="${extensions[$uuid]}"
        log "[$current/$total] $name"

        if install_extension "$uuid" "$name"; then
            ((installed++))
        fi

        sleep 0.3  # サーバー負荷軽減
    done

    echo
    title "🔧 拡張機能を有効化中..."
    current=0
    for uuid in "${!extensions[@]}"; do
        ((current++))
        local name="${extensions[$uuid]}"
        log "[$current/$total] $name"

        if enable_extension "$uuid" "$name"; then
            ((enabled++))
        fi
    done

    echo
    title "📊 結果"
    title "======="
    success "インストール: $installed/$total"
    success "有効化: $enabled/$total"
    echo

    if [ "$installed" -eq "$total" ] && [ "$enabled" -eq "$total" ]; then
        title "🎉 全ての拡張機能のセットアップが完了しました！"
    else
        title "⚠️  一部で問題が発生しました"
    fi

    echo
    title "💡 次の手順:"
    echo "  1. GNOME Shell を再起動: Alt + F2 → 'r' → Enter"
    echo "  2. または、ログアウト/ログイン"
    echo "  3. 設定の確認は Extension Manager から"
    echo
}

main "$@"
