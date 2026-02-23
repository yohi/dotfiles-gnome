#!/bin/bash

# 🚀 GNOME Extensions 改良版自動インストールスクリプト
# より確実にextensions.gnome.orgから拡張機能をダウンロード・インストールします

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# スクリプトディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
TEMP_DIR="$(mktemp -d)" || { echo "Failed to create temp dir" >&2; exit 1; }

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

progress() {
    echo -e "${CYAN}[PROGRESS]${NC} $1"
}

# クリーンアップ関数
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# 環境チェック
check_environment() {
    title "🔍 環境チェック中..."

    # GNOME Shell の確認
    if ! command -v gnome-shell &> /dev/null; then
        error "GNOME Shell が見つかりません"
        exit 1
    fi

    local gnome_version
    gnome_version=$(gnome-shell --version | cut -d' ' -f3) || {
        error "gnome-shell バージョンの取得に失敗しました"
        exit 1
    }
    success "GNOME Shell バージョン: $gnome_version"

    # セッションタイプの確認
    if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
        warning "Waylandセッションを検出しました。一部の機能に制限がある場合があります"
    fi

    # 必要なコマンドの確認
    local required_commands=("curl" "unzip" "jq")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "$cmd が見つかりません。先に依存関係をインストールしてください"
            exit 1
        fi
    done

    success "環境チェック完了"
    return 0
}

# GNOME Shell拡張機能のメタデータを取得
get_extension_metadata() {
    local extension_uuid="$1"
    local gnome_version
    gnome_version=$(gnome-shell --version | cut -d' ' -f3 | cut -d'.' -f1,2) || {
        error "gnome-shell バージョンの取得に失敗しました"
        return 1
    }
    local api_url="https://extensions.gnome.org/extension-info/?uuid=${extension_uuid}&shell_version=${gnome_version}"

    # APIから拡張機能情報を取得
    local metadata
    metadata=$(curl -s "$api_url" 2>/dev/null) || {
        error "メタデータの取得に失敗しました"
        return 1
    }

    if echo "$metadata" | jq -e . >/dev/null 2>&1; then
        echo "$metadata"
        return 0
    else
        # GNOMEバージョンが対応していない場合、汎用バージョンを試行
        api_url="https://extensions.gnome.org/extension-info/?uuid=${extension_uuid}"
        metadata=$(curl -s "$api_url" 2>/dev/null)

        if echo "$metadata" | jq -e . >/dev/null 2>&1; then
            echo "$metadata"
            return 0
        fi
    fi

    return 1
}

# 拡張機能をダウンロードしてインストール
install_extension() {
    local extension_uuid="$1"
    local extension_name="$2"
    local install_dir="$EXTENSIONS_DIR/$extension_uuid"

    progress "拡張機能をインストール中: $extension_name"

    # 既にインストール済みかチェック
    if [ -d "$install_dir" ]; then
        success "$extension_name は既にインストールされています"
        return 0
    fi

    # メタデータを取得
    local metadata
    if ! metadata=$(get_extension_metadata "$extension_uuid"); then
        error "$extension_name のメタデータ取得に失敗しました"
        return 1
    fi

    # ダウンロードURLを抽出
    local download_url
    if ! download_url=$(echo "$metadata" | jq -r '.download_url // empty' 2>/dev/null); then
        error "$extension_name のダウンロードURL取得に失敗しました"
        return 1
    fi

    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        error "$extension_name はこのGNOMEバージョンに対応していません"
        return 1
    fi

    # 拡張機能をダウンロード
    local zip_file="$TEMP_DIR/${extension_uuid}.zip"
    log "ダウンロード中: $extension_name"

    if ! curl -L --fail --silent --show-error "https://extensions.gnome.org$download_url" -o "$zip_file"; then
        error "$extension_name のダウンロードに失敗しました"
        return 1
    fi

    # インストールディレクトリを作成
    mkdir -p "$install_dir"

    # ZIPファイルを解凍
    if ! unzip -q "$zip_file" -d "$install_dir"; then
        error "$extension_name の解凍に失敗しました"
        rm -rf "$install_dir"
        return 1
    fi

    # スキーマがある場合はコンパイル
    if [ -d "$install_dir/schemas" ] && ls "$install_dir/schemas"/*.gschema.xml >/dev/null 2>&1; then
        log "$extension_name のスキーマをコンパイル中..."
        if glib-compile-schemas "$install_dir/schemas" 2>/dev/null; then
            log "スキーマのコンパイルが完了しました"
        else
            warning "スキーマのコンパイルに失敗しましたが、続行します"
        fi
    fi

    success "$extension_name のインストールが完了しました"
    return 0
}

# 拡張機能を有効化
enable_extension() {
    local extension_uuid="$1"
    local extension_name="$2"

    log "$extension_name を有効化中..."

    # 拡張機能が存在するかチェック
    if ! [ -d "$EXTENSIONS_DIR/$extension_uuid" ]; then
        warning "$extension_name がインストールされていません"
        return 1
    fi

    # 既に有効化されているかチェック
    if gnome-extensions list --enabled | grep -q "$extension_uuid"; then
        success "$extension_name は既に有効化されています"
        return 0
    fi

    # 拡張機能を有効化
    if gnome-extensions enable "$extension_uuid" 2>/dev/null; then
        success "$extension_name を有効化しました"
        return 0
    else
        warning "$extension_name の有効化に失敗しました"
        return 1
    fi
}

# 拡張機能リストを読み込み
load_extensions_list() {
    local extensions_file="$SCRIPT_DIR/enabled-extensions.txt"

    if [ ! -f "$extensions_file" ]; then
        error "拡張機能リストファイルが見つかりません: $extensions_file"
        exit 1
    fi

    # コメント行と空行を除外してリストを作成
    grep -v '^#' "$extensions_file" | grep -v '^$' || true
}

# 拡張機能名を取得（extensions.gnome.org APIから）
get_extension_name() {
    local extension_uuid="$1"
    local metadata

    metadata=$(get_extension_metadata "$extension_uuid" 2>/dev/null || echo "")
    if [ -n "$metadata" ]; then
        echo "$metadata" | jq -r '.name // "Unknown Extension"' 2>/dev/null || echo "Unknown Extension"
    else
        echo "Unknown Extension"
    fi
}

# メイン実行関数
main() {
    echo ""
    title "🚀 GNOME Extensions 改良版自動セットアップ"
    title "=============================================="
    echo ""

    # 環境チェック
    check_environment
    echo ""

    # 拡張機能リストを読み込み
    title "📋 拡張機能リストを読み込み中..."
    local extensions_list
    extensions_list=$(load_extensions_list)

    if [ -z "$extensions_list" ]; then
        error "インストールする拡張機能が見つかりません"
        exit 1
    fi

    local total_count
    total_count=$(echo "$extensions_list" | wc -l)
    success "$total_count 個の拡張機能が見つかりました"
    echo ""

    # 拡張機能をインストール
    title "📦 拡張機能のインストールを開始..."
    local success_count=0
    local current=0

    while IFS= read -r extension_uuid; do
        [ -z "$extension_uuid" ] && continue

        current=$((current + 1))
        local extension_name
        extension_name=$(get_extension_name "$extension_uuid")

        progress "[$current/$total_count] $extension_name ($extension_uuid)"

        if install_extension "$extension_uuid" "$extension_name"; then
            success_count=$((success_count + 1))
        fi

        # サーバーへの負荷を軽減するため少し待機
        sleep 0.5
    done <<< "$extensions_list"

    echo ""
    title "🔧 拡張機能の有効化を開始..."
    local enabled_count=0
    current=0

    while IFS= read -r extension_uuid; do
        [ -z "$extension_uuid" ] && continue

        current=$((current + 1))
        local extension_name
        extension_name=$(get_extension_name "$extension_uuid")

        progress "[$current/$total_count] $extension_name を有効化中..."

        if enable_extension "$extension_uuid" "$extension_name"; then
            enabled_count=$((enabled_count + 1))
        fi
    done <<< "$extensions_list"

    echo ""
    title "📊 セットアップ結果"
    title "=================="
    success "インストール完了: $success_count/$total_count 個"
    success "有効化完了: $enabled_count/$total_count 個"
    echo ""

    if [ "$success_count" -eq "$total_count" ] && [ "$enabled_count" -eq "$total_count" ]; then
        title "🎉 すべての拡張機能のセットアップが完了しました！"
    else
        title "⚠️  一部の拡張機能でエラーが発生しました"
    fi

    echo ""
    title "💡 次の手順："
    echo "  1. GNOME Shell を再起動してください（Alt + F2 → 'r' → Enter）"
    echo "  2. または、ログアウト/ログインしてください"
    echo "  3. Extension Manager で各拡張機能の設定を確認してください"
    echo ""
}

# スクリプトの実行
main "$@"
