#!/bin/bash

# 🔧 GNOME Extensions スキーマ修復スクリプト
# GLib.FileError: gschemas.compiled ファイルが見つからない問題を修正

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ログ関数
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
title() { echo -e "${PURPLE}$1${NC}"; }

# 拡張機能ディレクトリ
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"

# 必要なツールのチェック
check_dependencies() {
    local missing_deps=()

    if ! command -v glib-compile-schemas >/dev/null 2>&1; then
        missing_deps+=("glib-compile-schemas")
    fi

    if ! command -v xmllint >/dev/null 2>&1; then
        missing_deps+=("xmllint")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "以下のツールが必要です:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        log "必要なパッケージをインストール中..."
        sudo apt update
        sudo apt install -y libglib2.0-dev-bin libglib2.0-dev libxml2-utils
        success "必要なパッケージのインストール完了"
    fi
}

# 個別拡張機能のスキーマをコンパイル
compile_extension_schema() {
    local extension_uuid="$1"
    local extension_dir="$EXTENSIONS_DIR/$extension_uuid"
    local schemas_dir="$extension_dir/schemas"

    if [ ! -d "$extension_dir" ]; then
        warning "$extension_uuid がインストールされていません"
        return 1
    fi

    log "$extension_uuid のスキーマをチェック中..."

    # スキーマディレクトリが存在するかチェック
    if [ ! -d "$schemas_dir" ]; then
        success "$extension_uuid にはスキーマがありません（正常）"
        return 0
    fi

    # .gschema.xml ファイルが存在するかチェック
    if ! ls "$schemas_dir"/*.gschema.xml >/dev/null 2>&1; then
        success "$extension_uuid にはスキーマファイルがありません（正常）"
        return 0
    fi

    # 既存のコンパイル済みファイルを削除
    rm -f "$schemas_dir/gschemas.compiled"

    # スキーマをコンパイル
    log "$extension_uuid のスキーマをコンパイル中..."
    if glib-compile-schemas "$schemas_dir" 2>/dev/null; then
        if [ -f "$schemas_dir/gschemas.compiled" ]; then
            success "$extension_uuid のスキーマをコンパイルしました"
            return 0
        else
            warning "$extension_uuid のスキーマコンパイルは成功しましたが、ファイルが見つかりません"
            return 1
        fi
    else
        error "$extension_uuid のスキーマコンパイルに失敗しました"

        # スキーマファイルの詳細情報を表示
        log "スキーマファイルの詳細:"
        ls -la "$schemas_dir"/ || true

        # スキーマファイルの内容を検証
        for schema_file in "$schemas_dir"/*.gschema.xml; do
            if [ -f "$schema_file" ]; then
                log "検証中: $(basename "$schema_file")"
                if xmllint --noout "$schema_file" 2>/dev/null; then
                    success "  XMLは有効です"
                else
                    warning "  XMLに問題があります"
                fi
            fi
        done

        return 1
    fi
}

# すべての拡張機能のスキーマをコンパイル
compile_all_schemas() {
    title "🔧 すべての拡張機能のスキーマをコンパイル中..."

    if [ ! -d "$EXTENSIONS_DIR" ]; then
        error "拡張機能ディレクトリが見つかりません: $EXTENSIONS_DIR"
        return 1
    fi

    local success_count=0
    local total_count=0
    local failed_extensions=()

    # 各拡張機能のディレクトリを確認
    for extension_dir in "$EXTENSIONS_DIR"/*; do
        if [ -d "$extension_dir" ]; then
            local extension_uuid=$(basename "$extension_dir")
            total_count=$((total_count + 1))

            if compile_extension_schema "$extension_uuid"; then
                success_count=$((success_count + 1))
            else
                failed_extensions+=("$extension_uuid")
            fi
        fi
    done

    echo ""
    title "📊 コンパイル結果"
    success "成功: $success_count/$total_count"

    if [ ${#failed_extensions[@]} -gt 0 ]; then
        warning "失敗した拡張機能:"
        for ext in "${failed_extensions[@]}"; do
            echo "  - $ext"
        done
    fi

    return 0
}

# 拡張機能を無効化・有効化してリフレッシュ
refresh_extensions() {
    title "🔄 拡張機能をリフレッシュ中..."

    if ! command -v gnome-extensions >/dev/null 2>&1; then
        warning "gnome-extensions コマンドが見つかりません"
        return 1
    fi

    # 現在有効な拡張機能のリストを取得
    local enabled_extensions=$(gnome-extensions list --enabled 2>/dev/null || echo "")

    if [ -z "$enabled_extensions" ]; then
        warning "有効な拡張機能が見つかりません"
        return 1
    fi

    # 各拡張機能を無効化してから有効化
    while IFS= read -r extension; do
        if [ -n "$extension" ]; then
            log "$extension をリフレッシュ中..."
            gnome-extensions disable "$extension" 2>/dev/null || true
            sleep 0.5
            gnome-extensions enable "$extension" 2>/dev/null || warning "$extension の有効化に失敗"
        fi
    done <<< "$enabled_extensions"

    success "拡張機能のリフレッシュ完了"
}

# 特定の拡張機能を修復
fix_specific_extension() {
    local extension_uuid="$1"

    title "🔧 $extension_uuid を修復中..."

    # スキーマをコンパイル
    if compile_extension_schema "$extension_uuid"; then
        # 拡張機能をリフレッシュ
        if command -v gnome-extensions >/dev/null 2>&1; then
            log "$extension_uuid をリフレッシュ中..."
            gnome-extensions disable "$extension_uuid" 2>/dev/null || true
            sleep 1
            gnome-extensions enable "$extension_uuid" 2>/dev/null || warning "$extension_uuid の有効化に失敗"
        fi

        success "$extension_uuid の修復完了"
        return 0
    else
        error "$extension_uuid の修復に失敗しました"
        return 1
    fi
}

# メイン実行関数
main() {
    echo ""
    title "🔧 GNOME Extensions スキーマ修復ツール"
    title "========================================"
    echo ""

    # 依存関係チェック
    check_dependencies
    echo ""

    # 引数チェック
    if [ $# -gt 0 ]; then
        case "$1" in
            "fix")
                if [ $# -eq 2 ]; then
                    # 特定の拡張機能を修復
                    fix_specific_extension "$2"
                else
                    # すべての拡張機能を修復
                    compile_all_schemas
                    echo ""
                    refresh_extensions
                fi
                ;;
            "compile")
                # スキーマのコンパイルのみ
                compile_all_schemas
                ;;
            "refresh")
                # 拡張機能のリフレッシュのみ
                refresh_extensions
                ;;
            *)
                echo "使用方法:"
                echo "  $0 fix              - すべての拡張機能を修復"
                echo "  $0 fix <extension>  - 特定の拡張機能を修復"
                echo "  $0 compile          - スキーマのコンパイルのみ"
                echo "  $0 refresh          - 拡張機能のリフレッシュのみ"
                exit 1
                ;;
        esac
    else
        # デフォルト: すべて修復
        compile_all_schemas
        echo ""
        refresh_extensions
    fi

    echo ""
    title "✅ 修復完了！"
    echo ""
    echo "💡 次の手順を実行してください："
    echo "  1. GNOME Shell を再起動（Alt + F2 → 'r' → Enter）"
    echo "  2. 問題が解決されない場合は、ログアウト/ログイン"
    echo "  3. Extension Manager で拡張機能の状態を確認"
    echo ""
}

# スクリプト実行
main "$@"
