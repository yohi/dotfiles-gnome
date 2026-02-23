#!/bin/bash

# Wezterm デフォルト端末設定スクリプト
# Author: y_ohi
# Description: NautilusでWeztermをデフォルト端末として使用するための設定スクリプト

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

# Weztermがインストールされているかチェック
check_wezterm_installation() {
    log_info "📋 Weztermのインストール状況を確認中..."

    if command -v wezterm >/dev/null 2>&1; then
        log_success "Weztermがインストールされています: $(which wezterm)"
        return 0
    elif [ -f "/usr/local/bin/wezterm" ]; then
        log_success "Weztermがインストールされています: /usr/local/bin/wezterm"
        return 0
    elif [ -f "$HOME/.local/bin/wezterm" ]; then
        log_success "Weztermがインストールされています: $HOME/.local/bin/wezterm"
        return 0
    else
        log_error "Weztermがインストールされていません"
        echo "Weztermをインストールしてから再実行してください"
        echo "インストール方法: https://wezfurlong.org/wezterm/install/linux.html"
        return 1
    fi
}

# Weztermのデスクトップエントリファイルを確認
check_wezterm_desktop_entry() {
    log_info "🖥️ Weztermのデスクトップエントリファイルを確認中..."

    local desktop_files=(
        "/usr/share/applications/wezterm.desktop"
        "/usr/local/share/applications/wezterm.desktop"
        "$HOME/.local/share/applications/wezterm.desktop"
    )

    for desktop_file in "${desktop_files[@]}"; do
        if [ -f "$desktop_file" ]; then
            log_success "デスクトップエントリファイルが見つかりました: $desktop_file"
            return 0
        fi
    done

    log_warning "Weztermのデスクトップエントリファイルが見つかりません"
    log_info "手動でデスクトップエントリファイルを作成します..."
    create_wezterm_desktop_entry
}

# Weztermのデスクトップエントリファイルを作成
create_wezterm_desktop_entry() {
    local desktop_dir="$HOME/.local/share/applications"
    local desktop_file="$desktop_dir/wezterm.desktop"

    log_info "📝 Weztermのデスクトップエントリファイルを作成中..."

    # ディレクトリが存在しない場合は作成
    mkdir -p "$desktop_dir"

    # デスクトップエントリファイルを作成
    cat > "$desktop_file" << 'EOF'
[Desktop Entry]
Name=WezTerm
Comment=A GPU-accelerated cross-platform terminal emulator and multiplexer
Keywords=terminal;
Exec=wezterm start --cwd %f
Icon=wezterm
StartupNotify=true
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
Actions=new-window;

[Desktop Action new-window]
Name=New Window
Exec=wezterm start
EOF

    if [ -f "$desktop_file" ]; then
        log_success "デスクトップエントリファイルを作成しました: $desktop_file"

        # アプリケーションキャッシュを更新
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$desktop_dir" 2>/dev/null || true
        fi
    else
        log_error "デスクトップエントリファイルの作成に失敗しました"
        return 1
    fi
}

# デフォルト端末をWeztermに設定
set_wezterm_as_default() {
    log_info "⚙️ Weztermをデフォルト端末に設定中..."

    # gsettingsでデフォルト端末を設定
    if gsettings set org.gnome.desktop.default-applications.terminal exec 'wezterm' 2>/dev/null; then
        log_success "デフォルト端末実行ファイルを設定: wezterm"
    else
        log_error "デフォルト端末実行ファイルの設定に失敗しました"
    fi

    if gsettings set org.gnome.desktop.default-applications.terminal exec-arg '' 2>/dev/null; then
        log_success "デフォルト端末実行引数を設定: (空文字)"
    else
        log_error "デフォルト端末実行引数の設定に失敗しました"
    fi

    # update-alternativesでシステムレベルのデフォルト端末も設定
    local wezterm_path
    if ! wezterm_path=$(command -v wezterm); then
        wezterm_path=""
    fi

    if [ -n "$wezterm_path" ]; then
        log_info "🔧 update-alternativesでシステムレベルのデフォルト端末を設定中..."
        if sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$wezterm_path" 50 >/dev/null 2>&1; then
            log_success "update-alternativesでweztermを優先度50で設定"
        else
            log_warning "update-alternativesの設定に失敗しました（権限不足の可能性）"
            log_info "手動で設定してください: sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator $wezterm_path 50"
        fi
    else
        log_error "weztermのパスが見つかりません"
    fi
}

# 現在のデフォルト端末設定を確認
check_current_default_terminal() {
    log_info "🔍 現在のデフォルト端末設定を確認中..."

    local current_exec
    local current_arg
    local alternatives_current

    current_exec=$(gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null || echo "設定なし")
    current_arg=$(gsettings get org.gnome.desktop.default-applications.terminal exec-arg 2>/dev/null || echo "設定なし")
    alternatives_current=$(update-alternatives --query x-terminal-emulator 2>/dev/null | grep "Value:" | cut -d' ' -f2 || echo "設定なし")

    echo "現在の設定:"
    echo "  gsettings実行ファイル: $current_exec"
    echo "  gsettings実行引数: $current_arg"
    echo "  update-alternatives: $alternatives_current"

    local gsettings_ok=false
    local alternatives_ok=false

    if [[ "$current_exec" == "'wezterm'" ]]; then
        log_success "✓ gsettingsでWeztermが設定されています"
        gsettings_ok=true
    else
        log_warning "✗ gsettingsでWeztermが設定されていません"
    fi

    if [[ "$alternatives_current" == *"wezterm"* ]]; then
        log_success "✓ update-alternativesでWeztermが設定されています"
        alternatives_ok=true
    else
        log_warning "✗ update-alternativesでWeztermが設定されていません"
    fi

    if [[ "$gsettings_ok" == true && "$alternatives_ok" == true ]]; then
        log_success "Weztermが完全にデフォルト端末に設定されています"
        return 0
    else
        log_warning "Weztermの設定が不完全です"
        return 1
    fi
}

# Nautilus（ファイルマネージャー）のプラグインを確認
check_nautilus_terminal_plugin() {
    log_info "📁 Nautilusの端末プラグインを確認中..."

    # nautilus-open-terminalパッケージの確認
    local has_nautilus_open_terminal=false
    if command -v dpkg >/dev/null 2>&1; then
        if dpkg-query -W -f='${Status}' nautilus-open-terminal 2>/dev/null | grep -q "install ok installed"; then
            has_nautilus_open_terminal=true
        fi
    elif command -v rpm >/dev/null 2>&1; then
        if rpm -q nautilus-open-terminal >/dev/null 2>&1; then
            has_nautilus_open_terminal=true
        fi
    elif command -v pacman >/dev/null 2>&1; then
        if pacman -Qs nautilus-open-terminal >/dev/null 2>&1; then
            has_nautilus_open_terminal=true
        fi
    else
        if command -v nautilus-open-terminal >/dev/null 2>&1; then
            has_nautilus_open_terminal=true
        fi
    fi

    if [ "$has_nautilus_open_terminal" = true ]; then
        log_success "nautilus-open-terminalパッケージがインストールされています"
    else
        log_warning "nautilus-open-terminalパッケージがインストールされていません"
        log_info "インストールを推奨します: 各ディストリビューションのパッケージマネージャでインストールしてください（例: sudo apt install nautilus-open-terminal）"
    fi

    # Nautilusの再起動を促す
    log_info "変更を反映するため、Nautilusの再起動が必要です"
}

# 設定をテスト
test_terminal_setting() {
    log_info "🧪 設定をテスト中..."

    local test_passed=true

    # gsettingsの設定を確認
    if command -v gsettings >/dev/null 2>&1; then
        local test_exec
        test_exec=$(gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null)

        if [[ "$test_exec" == "'wezterm'" ]]; then
            log_success "✓ gsettingsの設定が正しく適用されています"
        else
            log_error "✗ gsettingsの設定に問題があります: $test_exec"
            test_passed=false
        fi
    else
        log_warning "⚠ gsettingsコマンドが見つかりません。テストをスキップします"
    fi

    # update-alternativesの設定を確認
    if command -v update-alternatives >/dev/null 2>&1; then
        local alternatives_current
        alternatives_current=$(update-alternatives --query x-terminal-emulator 2>/dev/null | grep "Value:" | cut -d' ' -f2 || echo "")

        if [[ "$alternatives_current" == *"wezterm"* ]]; then
            log_success "✓ update-alternativesの設定が正しく適用されています"
        else
            log_error "✗ update-alternativesの設定に問題があります: $alternatives_current"
            test_passed=false
        fi
    else
        log_warning "⚠ update-alternativesコマンドが見つかりません。テストをスキップします"
    fi

    # x-terminal-emulatorコマンドのテスト
    if command -v x-terminal-emulator >/dev/null 2>&1; then
        if x-terminal-emulator --version 2>/dev/null | grep -q "wezterm"; then
            log_success "✓ x-terminal-emulatorがweztermを指しています"
        else
            log_error "✗ x-terminal-emulatorがweztermを指していません"
            test_passed=false
        fi
    else
        log_warning "⚠ x-terminal-emulatorコマンドが見つかりません。テストをスキップします"
    fi

    # コマンドの実行確認
    if command -v wezterm >/dev/null 2>&1; then
        log_success "✓ weztermコマンドが利用可能です"
    else
        log_error "✗ weztermコマンドが見つかりません"
        test_passed=false
    fi

    if [[ "$test_passed" == true ]]; then
        return 0
    else
        return 1
    fi
}

# Nautilusを再起動
restart_nautilus() {
    log_info "🔄 Nautilusを再起動中..."

    # Nautilusのプロセスを停止
    if pgrep nautilus >/dev/null 2>&1; then
        nautilus -q 2>/dev/null || killall nautilus 2>/dev/null || true
        sleep 2
        log_success "Nautilusプロセスを停止しました"
    fi

    # Nautilusを起動（バックグラウンド）
    nautilus --no-desktop >/dev/null 2>&1 &
    disown 2>/dev/null || true

    log_success "Nautilusを再起動しました"
}

# メイン関数
main() {
    echo -e "${BLUE}"
    cat << 'EOF'
 __        __      _____
 \ \      / /__ __|_   _|__ _ __ _ __ ___
  \ \ /\ / / _ \__  | |/ _ \ '__| '_ ` _ \
   \ V  V /  __/ /  | |  __/ |  | | | | | |
    \_/\_/ \___/_/   |_|\___|_|  |_| |_| |_|

            デフォルト端末設定スクリプト v1.2
EOF
    echo -e "${NC}"

    case "${1:-}" in
        --check)
            check_current_default_terminal
            check_wezterm_installation
            check_wezterm_desktop_entry
            check_nautilus_terminal_plugin
            ;;
        --test)
            test_terminal_setting
            ;;
        --restart-nautilus)
            restart_nautilus
            ;;
        --help|-h)
            echo "使用方法: $0 [オプション]"
            echo ""
            echo "オプション:"
            echo "  (なし)                Weztermをデフォルト端末に設定"
            echo "  --check              現在の設定を確認"
            echo "  --test               設定をテスト"
            echo "  --restart-nautilus   Nautilusを再起動"
            echo "  --help, -h           このヘルプを表示"
            exit 0
            ;;
        "")
            # デフォルト: Weztermをデフォルト端末に設定
            log_info "🚀 Weztermをデフォルト端末に設定を開始します"
            echo ""

            # 事前チェック
            if ! check_wezterm_installation; then
                exit 1
            fi

            check_wezterm_desktop_entry
            echo ""

            # 現在の設定を確認
            if check_current_default_terminal; then
                echo ""
                log_info "設定は既に完了しています"
                read -p "設定を再適用しますか？ (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    log_info "処理を終了します"
                    exit 0
                fi
            fi

            echo ""

            # デフォルト端末を設定
            set_wezterm_as_default
            echo ""

            # 設定をテスト
            if test_terminal_setting; then
                echo ""
                log_success "🎉 Weztermのデフォルト端末設定が完了しました！"
                echo ""

                # Nautilusプラグインの確認
                check_nautilus_terminal_plugin
                echo ""

                log_info "📋 次の手順:"
                echo "1. Nautilus（ファイルマネージャー）を再起動してください"
                echo "2. フォルダを右クリックして「端末で開く」を確認してください"
                echo ""

                read -p "Nautilusを今すぐ再起動しますか？ (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    restart_nautilus
                    echo ""
                    log_success "設定が完了しました！フォルダを右クリックして「端末で開く」を試してください"
                fi
            else
                log_error "設定のテストに失敗しました"
                exit 1
            fi
            ;;
        *)
            log_error "不明なオプション: $1"
            echo "ヘルプを表示するには: $0 --help"
            exit 1
            ;;
    esac
}

# エラーハンドリング
trap 'log_error "スクリプト実行中にエラーが発生しました"' ERR

# スクリプト実行
main "$@"
