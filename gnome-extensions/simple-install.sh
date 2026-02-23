#!/bin/bash
set -euo pipefail

# 🚀 GNOME Extensions シンプル自動インストールスクリプト
# より堅牢でシンプルなバージョン

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# スクリプトディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"

# ログ関数
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
title() { echo -e "${PURPLE}$1${NC}"; }

# 環境チェック
check_environment() {
    title "🔍 環境チェック中..."

    if ! command -v gnome-shell >/dev/null 2>&1; then
        error "GNOME Shell が見つかりません"
        return 1
    fi

    if ! command -v curl >/dev/null 2>&1; then
        error "curl が見つかりません"
        return 1
    fi

    if ! command -v unzip >/dev/null 2>&1; then
        error "unzip が見つかりません"
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        error "jq が見つかりません"
        return 1
    fi

    local gnome_version
    gnome_version=$(gnome-shell --version 2>/dev/null | cut -d' ' -f3 || echo "Unknown")
    success "GNOME Shell バージョン: $gnome_version"
    success "環境チェック完了"
    return 0
}

# 拡張機能をインストール
install_extension() {
    local extension_uuid="$1"
    local install_dir="$EXTENSIONS_DIR/$extension_uuid"

    log "拡張機能をインストール中: $extension_uuid"

    # 既にインストール済みかチェック
    if [ -d "$install_dir" ]; then
        success "$extension_uuid は既にインストールされています"
        return 0
    fi

    # メタデータを取得
    local gnome_version
    gnome_version=$(gnome-shell --version 2>/dev/null | cut -d' ' -f3 | cut -d'.' -f1,2 || echo "48")
    local api_url="https://extensions.gnome.org/extension-info/?uuid=${extension_uuid}&shell_version=${gnome_version}"

    local temp_dir
    if ! temp_dir=$(mktemp -d); then
        error "一時ディレクトリの作成に失敗しました"
        return 1
    fi

    # APIからメタデータを取得
    if ! curl -s "$api_url" -o "$temp_dir/metadata.json" 2>/dev/null; then
        # バージョン指定なしで再試行
        api_url="https://extensions.gnome.org/extension-info/?uuid=${extension_uuid}"
        if ! curl -s "$api_url" -o "$temp_dir/metadata.json" 2>/dev/null; then
            warning "$extension_uuid のメタデータ取得に失敗しました"
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    # ダウンロードURLを抽出
    local download_url=""
    if command -v jq >/dev/null 2>&1; then
        download_url=$(cat "$temp_dir/metadata.json" | jq -r '.download_url // empty' 2>/dev/null || echo "")
    fi

    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        warning "$extension_uuid はこのGNOMEバージョンに対応していません"
        rm -rf "$temp_dir"
        return 1
    fi

    # 拡張機能をダウンロード
    local zip_file="$temp_dir/extension.zip"
    if ! curl -L --fail --silent "https://extensions.gnome.org$download_url" -o "$zip_file" 2>/dev/null; then
        warning "$extension_uuid のダウンロードに失敗しました"
        rm -rf "$temp_dir"
        return 1
    fi

    # インストールディレクトリを作成
    mkdir -p "$install_dir"

    # ZIPファイルを解凍
    if ! unzip -q "$zip_file" -d "$install_dir" 2>/dev/null; then
        error "$extension_uuid の解凍に失敗しました"
        rm -rf "$install_dir" "$temp_dir"
        return 1
    fi

    # スキーマコンパイル
    if [ -d "$install_dir/schemas" ] && ls "$install_dir/schemas"/*.gschema.xml >/dev/null 2>&1; then
        if command -v glib-compile-schemas >/dev/null 2>&1; then
            glib-compile-schemas "$install_dir/schemas" 2>/dev/null || true
        fi
    fi

    # クリーンアップ
    rm -rf "$temp_dir"

    success "$extension_uuid のインストールが完了しました"
    return 0
}

# 拡張機能を有効化
enable_extension() {
    local extension_uuid="$1"

    if ! [ -d "$EXTENSIONS_DIR/$extension_uuid" ]; then
        warning "$extension_uuid がインストールされていません"
        return 1
    fi

    if command -v gnome-extensions >/dev/null 2>&1; then
        if gnome-extensions list --enabled 2>/dev/null | grep -q "$extension_uuid"; then
            success "$extension_uuid は既に有効化されています"
            return 0
        fi

        if gnome-extensions enable "$extension_uuid" 2>/dev/null; then
            success "$extension_uuid を有効化しました"
            return 0
        else
            warning "$extension_uuid の有効化に失敗しました"
            return 1
        fi
    else
        warning "gnome-extensions コマンドが見つかりません"
        return 1
    fi
}

# メイン実行関数
main() {
    echo ""
    title "🚀 GNOME Extensions シンプル自動インストール"
    title "============================================="
    echo ""

    # 環境チェック
    if ! check_environment; then
        error "環境チェックに失敗しました"
        exit 1
    fi
    echo ""

    # 拡張機能リスト
    local extensions_file="$SCRIPT_DIR/enabled-extensions.txt"
    if [ ! -f "$extensions_file" ]; then
        error "拡張機能リストファイルが見つかりません: $extensions_file"
        exit 1
    fi

    # 拡張機能リストを読み込み
    local extensions_list=""
    while IFS= read -r line || [ -n "$line" ]; do
        # コメント行と空行をスキップ
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            continue
        fi
        extensions_list="$extensions_list$line"$'\n'
    done < "$extensions_file"

    if [ -z "$extensions_list" ]; then
        error "インストールする拡張機能が見つかりません"
        exit 1
    fi

    local total_count
    total_count=$(printf '%s' "$extensions_list" | wc -l)
    success "$total_count 個の拡張機能が見つかりました"
    echo ""

    # 拡張機能をインストール
    title "📦 拡張機能のインストールを開始..."
    local success_count=0
    local current=0

    while IFS= read -r extension_uuid; do
        [ -z "$extension_uuid" ] && continue

        current=$((current + 1))
        echo -e "${BLUE}[$current/$total_count]${NC} $extension_uuid"

        if install_extension "$extension_uuid"; then
            success_count=$((success_count + 1))
        fi

        # 少し待機
        sleep 0.3
    done <<< "$extensions_list"

    echo ""
    title "🔧 拡張機能の有効化を開始..."

    while IFS= read -r extension_uuid; do
        [ -z "$extension_uuid" ] && continue

        log "$extension_uuid を有効化中..."
        enable_extension "$extension_uuid"

        sleep 0.1
    done <<< "$extensions_list"

    echo ""
    title "🎉 インストール処理が完了しました！"
    echo ""
    title "💡 次の手順："
    echo "  1. GNOME Shell を再起動してください（Alt + F2 → 'r' → Enter）"
    echo "  2. または、ログアウト/ログインしてください"
    echo "  3. Extensions アプリで各拡張機能を確認してください"
    echo ""
}

# スクリプト実行
main "$@"
