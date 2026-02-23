#!/bin/bash

# 🚀 GNOME Extensions 自動インストール & 設定スクリプト
# このスクリプトは必要な依存関係の自動インストールから拡張機能の設定まで一括で行います

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# ログ関数
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

title() {
    echo -e "${PURPLE}$1${NC}"
}

# 環境チェック
check_environment() {
    title "🔍 環境チェック中..."
    
    # GNOME Shell の確認
    if ! command -v gnome-shell &> /dev/null; then
        error "GNOME Shell が見つかりません"
        exit 1
    fi
    
    local gnome_version=$(gnome-shell --version | cut -d' ' -f3)
    success "GNOME Shell バージョン: $gnome_version"
    
    # セッションタイプの確認
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        warning "Waylandセッションを検出しました。一部の機能に制限がある場合があります"
    fi
    
    success "環境チェック完了"
}

# 依存関係の自動インストール
install_dependencies() {
    title "📦 依存関係をインストール中..."
    
    # システムパッケージの更新
    log "システムパッケージを更新中..."
    sudo apt update -qq
    
    # 必要なパッケージをインストール
    local required_packages=(
        "curl"
        "wget" 
        "unzip"
        "python3"
        "python3-requests"
        "jq"
        "libglib2.0-dev"
        "gettext"
    )
    
    # 不足しているパッケージを収集
    local missing_packages=()
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            missing_packages+=("$package")
        else
            log "$package は既にインストールされています"
        fi
    done
    
    # 不足しているパッケージを一括でインストール
    if [ ${#missing_packages[@]} -gt 0 ]; then
        log "不足しているパッケージをインストール中: ${missing_packages[*]}"
        sudo apt install -y "${missing_packages[@]}"
        success "${#missing_packages[@]} 個のパッケージのインストールが完了しました"
    else
        success "すべての必要なパッケージは既にインストールされています"
    fi
    
    # gnome-shell-extension-installer のインストール
    if ! command -v gnome-shell-extension-installer >/dev/null 2>&1; then
        log "gnome-shell-extension-installer をインストール中..."
        sudo wget -O /usr/local/bin/gnome-shell-extension-installer \
            "https://raw.githubusercontent.com/brunelli/gnome-shell-extension-installer/master/gnome-shell-extension-installer"
        sudo chmod +x /usr/local/bin/gnome-shell-extension-installer
        success "gnome-shell-extension-installer のインストール完了"
    else
        success "gnome-shell-extension-installer は既にインストールされています"
    fi
    
    # gext のインストール（オプション）
    if ! command -v gext &> /dev/null; then
        log "gext をインストール中..."
        pip3 install --user --break-system-packages gnome-extensions-cli 2>/dev/null || warning "gext のインストールに失敗しました（オプションなので続行します）"
    fi
    
    success "依存関係のインストール完了"
}

# メイン実行
main() {
    echo ""
    title "🚀 GNOME Extensions 自動セットアップ"
    title "=================================="
    echo ""
    
    # 環境チェック
    check_environment
    echo ""
    
    # 依存関係インストール
    install_dependencies
    echo ""
    
    # メインのインストールスクリプトを実行
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [ -f "$script_dir/install-extensions.sh" ]; then
        title "🔧 拡張機能のインストールと設定を実行中..."
        "$script_dir/install-extensions.sh" install
        success "自動セットアップが完了しました！"
    else
        error "install-extensions.sh が見つかりません"
        exit 1
    fi
    
    echo ""
    title "🎉 セットアップ完了！"
    echo ""
    echo "💡 次の手順を実行してください："
    echo "  1. GNOME Shell を再起動してください（Alt + F2 → 'r' → Enter）"
    echo "  2. 拡張機能が正常に動作することを確認してください"
    echo "  3. Extension Manager で個別設定を調整してください"
    echo "  4. 完全に反映するにはログアウト/ログインを推奨します"
    echo ""
}

# スクリプトの実行
main "$@" 