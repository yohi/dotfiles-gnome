#!/bin/bash

# Mozc UT辞書自動インポートスクリプト
# このスクリプトは独立してバックグラウンドで実行されます

set -e

# 色付きメッセージ用の関数
print_status() {
    echo "🤖 $1"
}

print_success() {
    echo "✅ $1"
}

print_error() {
    echo "❌ $1"
}

print_warning() {
    echo "⚠️  $1"
}

# 引数の確認
if [ $# -ne 3 ]; then
    print_error "使用法: $0 <辞書ファイル> <データベースファイル> <dotfilesディレクトリ>"
    exit 1
fi

DICT_FILE="$1"
DB_FILE="$2"
REPO_ROOT="$3"
LOG_FILE="${DB_FILE}.import.log"

# ログディレクトリの作成
mkdir -p "$(dirname "$LOG_FILE")"

# ログファイルの初期化
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

print_status "Mozc UT辞書自動インポート開始"
print_status "辞書ファイル: $DICT_FILE"
print_status "データベースファイル: $DB_FILE"
print_status "ログファイル: $LOG_FILE"

# 辞書ファイルの存在確認
if [ ! -f "$DICT_FILE" ]; then
    print_error "辞書ファイルが見つかりません: $DICT_FILE"
    exit 1
fi

# Mozcサービスの停止
print_status "Mozcサービスを停止中..."
pkill -f mozc_server 2>/dev/null || true
pkill -f mozc_renderer 2>/dev/null || true
sleep 2

# データベースディレクトリの作成
print_status "データベースディレクトリを作成中..."
mkdir -p "$(dirname "$DB_FILE")"

# 既存のデータベースをバックアップ
if [ -f "$DB_FILE" ]; then
    print_status "既存のユーザー辞書をバックアップ中..."
    cp "$DB_FILE" "${DB_FILE}.bak"
fi

# Pythonスクリプトの存在確認
PYTHON_SCRIPT="$REPO_ROOT/mozc/import_ut_dictionary.py"
if [ ! -f "$PYTHON_SCRIPT" ]; then
    print_error "インポートスクリプトが見つかりません: $PYTHON_SCRIPT"
    exit 1
fi

# 既存のフラグファイルを削除
rm -f "${DB_FILE}.success" "${DB_FILE}.failed"

# 自動インポート実行
print_status "専用Pythonスクリプトを使用してインポート中..."
print_status "処理には5-10分程度かかります。しばらくお待ちください..."

if python3 "$PYTHON_SCRIPT" "$DICT_FILE" "$DB_FILE"; then
    print_success "辞書の自動インポートが完了しました"

    # 成功フラグファイルの作成
    touch "${DB_FILE}.success"
else
    print_error "自動インポートに失敗しました"

    # 失敗フラグファイルの作成
    touch "${DB_FILE}.failed"
    exit 1
fi

# Mozc設定の更新
print_status "Mozc設定ファイルを更新中..."
CONFIG_DIR="$(dirname "$(dirname "$(readlink -f "$DB_FILE")")")"
mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_DIR/config1.db" ]; then
    print_status "Mozc設定データベースを初期化中..."
    touch "$CONFIG_DIR/config1.db"
fi

# ユーザー辞書パスの設定
print_status "ユーザー辞書パスを設定中..."
if command -v sqlite3 >/dev/null 2>&1; then
    sqlite3 "$CONFIG_DIR/config1.db" "CREATE TABLE IF NOT EXISTS config (name TEXT PRIMARY KEY, value TEXT);" 2>/dev/null || true
    escaped_db_file="${DB_FILE//\'/\'\'}"
    sqlite3 "$CONFIG_DIR/config1.db" "INSERT OR REPLACE INTO config (name, value) VALUES ('user_dictionary_file', '$escaped_db_file');" 2>/dev/null || true
    print_success "設定データベースが更新されました"
fi

# IBusの再起動
print_status "IBusを再起動中..."
ibus restart 2>/dev/null || true
sleep 3

print_success "Mozc UT辞書の自動インポートが完了しました！"
print_status "日本語入力で新しい辞書が利用できます"
