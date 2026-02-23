#!/bin/bash

# Mozc UT辞書インポート進捗チェックスクリプト

# 引数の確認
if [ $# -ne 1 ]; then
    echo "使用法: $0 <データベースファイル>"
    exit 1
fi

DB_FILE="$1"
LOG_FILE="${DB_FILE}.import.log"
SUCCESS_FILE="${DB_FILE}.success"
FAILED_FILE="${DB_FILE}.failed"

# 色付きメッセージ用の関数
print_status() {
    echo "🔍 $1"
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

print_info() {
    echo "ℹ️  $1"
}

# 処理状況の確認
if [ -f "$SUCCESS_FILE" ]; then
    print_success "辞書インポートが完了しています"

    if [ -f "$DB_FILE" ]; then
        print_info "データベースファイル: $DB_FILE"

        # データベースの情報を表示
        if command -v sqlite3 >/dev/null 2>&1; then
            ENTRY_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM user_dictionary WHERE comment LIKE 'UT辞書%';" 2>/dev/null || echo "0")
            print_info "インポート済みエントリ数: $ENTRY_COUNT"
        fi
    fi

    exit 0

elif [ -f "$FAILED_FILE" ]; then
    print_error "辞書インポートが失敗しました"

    if [ -f "$LOG_FILE" ]; then
        print_info "ログファイル: $LOG_FILE"
        print_info "最後のエラーメッセージ:"
        tail -10 "$LOG_FILE" | grep -E "❌|ERROR|エラー" | tail -3
    fi

    exit 1

else
    # 実行中かどうかを確認
    if pgrep -f "setup_mozc_import.sh" >/dev/null 2>&1; then
        print_status "辞書インポートが実行中です..."

        if [ -f "$LOG_FILE" ]; then
            print_info "ログファイル: $LOG_FILE"
            print_info "最新の進捗:"
            tail -5 "$LOG_FILE" | grep -E "🤖|✅|📊|処理済み" | tail -3
        fi

        exit 2
    else
        print_warning "辞書インポートが実行されていません"

        if [ -f "$LOG_FILE" ]; then
            print_info "前回のログファイル: $LOG_FILE"
            print_info "最後のメッセージ:"
            tail -5 "$LOG_FILE"
        fi

        exit 3
    fi
fi
