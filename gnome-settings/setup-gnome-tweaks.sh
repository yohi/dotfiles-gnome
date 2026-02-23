#!/bin/bash

# Gnome Tweaks設定復元スクリプト
# Author: y_ohi
# Description: Gnome Tweaksで設定可能な項目を自動的に復元するスクリプト

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

# dconfの設定を適用する関数
apply_dconf_setting() {
    local key="$1"
    local value="$2"
    local description="$3"
    
    if dconf write "$key" "$value" 2>/dev/null; then
        log_success "$description"
    else
        log_error "$description の設定に失敗しました"
    fi
}

# 設定を適用する関数
apply_gnome_tweaks_settings() {
    log_info "🎨 Gnome Tweaks設定を適用中..."
    
    # ========================================
    # 外観設定 (Appearance)
    # ========================================
    log_info "🎨 外観設定を適用中..."
    
    # テーマ設定
    apply_dconf_setting "/org/gnome/desktop/interface/gtk-theme" "'Yaru-red'" "GTKテーマ: Yaru-red"
    apply_dconf_setting "/org/gnome/desktop/interface/icon-theme" "'Yaru-red'" "アイコンテーマ: Yaru-red"
    apply_dconf_setting "/org/gnome/desktop/interface/cursor-theme" "'Yaru'" "カーソルテーマ: Yaru"
    apply_dconf_setting "/org/gnome/shell/extensions/user-theme/name" "'Yaru'" "シェルテーマ: Yaru"
    
    # カラースキーム
    apply_dconf_setting "/org/gnome/desktop/interface/color-scheme" "'prefer-light'" "カラースキーム: ライト"
    
    # ========================================
    # フォント設定 (Fonts)
    # ========================================
    log_info "🔤 フォント設定を適用中..."
    
    apply_dconf_setting "/org/gnome/desktop/interface/font-name" "'BlexSansJP Nerd Font 11'" "インターフェースフォント"
    apply_dconf_setting "/org/gnome/desktop/interface/document-font-name" "'BlexSansJP Nerd Font 11'" "ドキュメントフォント"
    apply_dconf_setting "/org/gnome/desktop/interface/monospace-font-name" "'BlexSansJP Nerd Font 13'" "等幅フォント"
    apply_dconf_setting "/org/gnome/desktop/interface/font-hinting" "'slight'" "フォントヒンティング"
    
    # ========================================
    # トップバー設定 (Top Bar)
    # ========================================
    log_info "📊 トップバー設定を適用中..."
    
    apply_dconf_setting "/org/gnome/desktop/interface/clock-show-seconds" "true" "時計に秒を表示"
    apply_dconf_setting "/org/gnome/desktop/interface/clock-show-weekday" "true" "時計に曜日を表示"
    apply_dconf_setting "/org/gnome/desktop/interface/show-battery-percentage" "true" "バッテリー残量を表示"
    
    # ========================================
    # ウィンドウ設定 (Windows)
    # ========================================
    log_info "🪟 ウィンドウ設定を適用中..."
    
    apply_dconf_setting "/org/gnome/desktop/wm/preferences/focus-mode" "'click'" "ウィンドウフォーカスモード: クリック"
    apply_dconf_setting "/org/gnome/desktop/interface/enable-animations" "true" "アニメーションを有効化"
    
    # ========================================
    # ワークスペース設定 (Workspaces)
    # ========================================
    log_info "🗂️ ワークスペース設定を適用中..."
    
    apply_dconf_setting "/org/gnome/mutter/dynamic-workspaces" "true" "動的ワークスペース"
    apply_dconf_setting "/org/gnome/mutter/workspaces-only-on-primary" "true" "プライマリモニターのみでワークスペース"
    
    # ========================================
    # キーボード設定 (Keyboard & Mouse)
    # ========================================
    log_info "⌨️ キーボード設定を適用中..."
    
    # 入力ソース設定
    apply_dconf_setting "/org/gnome/desktop/input-sources/sources" "[('ibus', 'mozc-jp'), ('xkb', 'us')]" "入力ソース: mozc + US"
    apply_dconf_setting "/org/gnome/desktop/input-sources/xkb-options" "['caps:none']" "CapsLockを無効化"
    apply_dconf_setting "/org/gnome/desktop/input-sources/per-window" "false" "ウィンドウごとの入力ソース無効"
    apply_dconf_setting "/org/gnome/desktop/input-sources/show-all-sources" "true" "全入力ソースを表示"
    
    # ========================================
    # 起動アプリケーション設定 (Startup Applications)
    # ========================================
    log_info "🚀 お気に入りアプリケーション設定を適用中..."
    
    # お気に入りアプリの設定 (共有ベースライン)
    FAVORITE_APPS="['org.gnome.Nautilus.desktop', 'com.gexperts.Tilix.desktop', 'wezterm.desktop', 'cursor.desktop', 'code.desktop', 'devtoys.desktop', 'google-chrome.desktop', 'google-chrome-beta.desktop', 'slack.desktop', 'synochat.desktop', 'discord.desktop', 'pgadmin4.desktop', 'mysql-workbench.desktop', 'tableplus.desktop', 'beekeeper-studio.desktop', 'dbgate.desktop', 'dbeaver-ce_dbeaver-ce.desktop', 'Postman.desktop', 'wps-office-prometheus.desktop', 'com.mattjakeman.ExtensionManager.desktop', 'org.gnome.Meld.desktop', 'filezilla.desktop', 'Zoom.desktop', 'com.bitwarden.desktop.desktop', 'claude-desktop.desktop']"
    apply_dconf_setting "/org/gnome/shell/favorite-apps" "$FAVORITE_APPS" "お気に入りアプリケーション"
    
    # ローカルのホスト専用お気に入りアプリがあれば追加する仕組み（別スクリプト/設定で実行）
    if [ -f "$HOME/.config/dotfiles-gnome/local-favorite-apps.sh" ]; then
        log_info "ホスト専用のお気に入りアプリを追加中..."
        bash "$HOME/.config/dotfiles-gnome/local-favorite-apps.sh"
    fi
    
    # ========================================
    # 拡張機能設定 (Extensions)
    # ========================================
    log_info "🧩 拡張機能設定を適用中..."
    
    # 有効な拡張機能
    ENABLED_EXTENSIONS="['bluetooth-quick-connect@bjarosze.gmail.com', 'tweaks-system-menu@extensions.gnome-shell.fifi.org', 'bluetooth-battery@michalw.github.com', 'window-app-switcher-on-active-monitor@NiKnights.com', 'ding@rastersoft.com', 'ubuntu-dock@ubuntu.com', 'Move_Clock@rmy.pobox.com', 'BringOutSubmenuOfPowerOffLogoutButton@pratap.fastmail.fm', 'PrivacyMenu@stuarthayhurst', 'vertical-workspaces@G-dH.github.com', 'search-light@icedman.github.com', 'monitor@astraext.github.io']"
    apply_dconf_setting "/org/gnome/shell/enabled-extensions" "$ENABLED_EXTENSIONS" "有効な拡張機能"
    
    # 無効な拡張機能
    DISABLED_EXTENSIONS="['tiling-assistant@ubuntu.com', 'just-perfection-desktop@just-perfection', 'docker@stickman_0x00.com', 'dejaview@hedgie.tech', 'gtk4-ding@smedius.gitlab.com', 'places-menu@gnome-shell-extensions.gcampax.github.com', 'user-theme@gnome-shell-extensions.gcampax.github.com', 'clipboard-indicator@tudmotu.com', 'gsconnect@andyholmes.github.io', 'gse-haguichi-indicator@ztefn.github.com', 'custom-hot-corners-extended@G-dH.github.com', 'simulate-switching-workspaces-on-active-monitor@micheledaros.com', 'dash2dock-lite@icedman.github.com', 'system-monitor-next@paradoxxx.zero.gmail.com']"
    apply_dconf_setting "/org/gnome/shell/disabled-extensions" "$DISABLED_EXTENSIONS" "無効な拡張機能"
    
    apply_dconf_setting "/org/gnome/shell/disable-user-extensions" "false" "ユーザー拡張機能を有効化"
    
    # ========================================
    # 実験的機能設定 (Experimental Features)
    # ========================================
    log_info "⚗️ 実験的機能設定を適用中..."
    
    apply_dconf_setting "/org/gnome/mutter/experimental-features" "['x11-randr-fractional-scaling']" "X11フラクショナルスケーリング"
    
    # ========================================
    # その他の設定 (Miscellaneous)
    # ========================================
    log_info "🔧 その他の設定を適用中..."
    
    # アクセシビリティ
    apply_dconf_setting "/org/gnome/desktop/a11y/keyboard/stickykeys-enable" "false" "固定キーを無効化"
    
    # 電源設定
    apply_dconf_setting "/org/gnome/shell/last-selected-power-profile" "'power-saver'" "電源プロファイル: 省電力"
    
    # Bluetooth設定
    apply_dconf_setting "/org/gnome/shell/had-bluetooth-devices-setup" "true" "Bluetoothデバイス設定済み"
    
    log_success "🎉 Gnome Tweaks設定の適用が完了しました！"
}

# 拡張機能の個別設定を適用する関数
apply_extension_settings() {
    log_info "🧩 拡張機能の個別設定を適用中..."
    
    # Ubuntu Dock設定
    log_info "🐳 Ubuntu Dock設定を適用中..."
    apply_dconf_setting "/org/gnome/shell/extensions/dash-to-dock/background-opacity" "0.8" "Dock背景透明度"
    apply_dconf_setting "/org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size" "30" "Dockアイコンサイズ"
    apply_dconf_setting "/org/gnome/shell/extensions/dash-to-dock/dock-fixed" "false" "Dockを固定しない"
    apply_dconf_setting "/org/gnome/shell/extensions/dash-to-dock/dock-position" "'BOTTOM'" "Dock位置: 下"
    apply_dconf_setting "/org/gnome/shell/extensions/dash-to-dock/extend-height" "false" "高さを拡張しない"
    apply_dconf_setting "/org/gnome/shell/extensions/dash-to-dock/height-fraction" "0.9" "高さの割合"
    apply_dconf_setting "/org/gnome/shell/extensions/dash-to-dock/preferred-monitor" "-2" "推奨モニター"
    apply_dconf_setting "/org/gnome/shell/extensions/dash-to-dock/preferred-monitor-by-connector" "'primary'" "プライマリモニター"
    
    # Bluetooth Quick Connect設定
    log_info "📶 Bluetooth Quick Connect設定を適用中..."
    apply_dconf_setting "/org/gnome/shell/extensions/bluetooth-quick-connect/bluetooth-auto-power-on" "true" "Bluetooth自動パワーオン"
    apply_dconf_setting "/org/gnome/shell/extensions/bluetooth-quick-connect/keep-menu-on-toggle" "true" "トグル時メニュー保持"
    apply_dconf_setting "/org/gnome/shell/extensions/bluetooth-quick-connect/refresh-button-on" "true" "リフレッシュボタン表示"
    apply_dconf_setting "/org/gnome/shell/extensions/bluetooth-quick-connect/show-battery-value-on" "true" "バッテリー値表示"
    
    # Bluetooth Battery Indicator設定
    log_info "🔋 Bluetooth Battery Indicator設定を適用中..."
    apply_dconf_setting "/org/gnome/shell/extensions/bluetooth-battery-indicator/hide-indicator" "true" "インジケーターを隠す"
    
    # Vertical Workspaces設定
    log_info "📐 Vertical Workspaces設定を適用中..."
    apply_dconf_setting "/org/gnome/shell/extensions/vertical-workspaces/ws-thumbnails-full" "false" "ワークスペースサムネイル全体表示しない"
    apply_dconf_setting "/org/gnome/shell/extensions/vertical-workspaces/ws-thumbnails-position" "5" "ワークスペースサムネイル位置"
    apply_dconf_setting "/org/gnome/shell/extensions/vertical-workspaces/wst-position-adjust" "-40" "ワークスペース位置調整"
    
    # Search Light設定
    log_info "🔍 Search Light設定を適用中..."
    apply_dconf_setting "/org/gnome/shell/extensions/search-light/animation-speed" "100.0" "アニメーション速度"
    apply_dconf_setting "/org/gnome/shell/extensions/search-light/blur-brightness" "0.6" "ブラー明度"
    apply_dconf_setting "/org/gnome/shell/extensions/search-light/blur-sigma" "30.0" "ブラーシグマ"
    apply_dconf_setting "/org/gnome/shell/extensions/search-light/entry-font-size" "1" "エントリーフォントサイズ"
    apply_dconf_setting "/org/gnome/shell/extensions/search-light/preferred-monitor" "0" "推奨モニター"
    apply_dconf_setting "/org/gnome/shell/extensions/search-light/scale-height" "0.1" "スケール高さ"
    apply_dconf_setting "/org/gnome/shell/extensions/search-light/scale-width" "0.1" "スケール幅"
    
    # Window App Switcher設定
    log_info "🪟 Window App Switcher設定を適用中..."
    apply_dconf_setting "/org/gnome/shell/extensions/window-app-switcher-on-active-monitor/ws-current-monitor" "true" "現在のモニター"
    apply_dconf_setting "/org/gnome/shell/extensions/window-app-switcher-on-active-monitor/ws-filter-monitor" "true" "モニターフィルター"
    
    # Tweaks System Menu設定
    log_info "⚙️ Tweaks System Menu設定を適用中..."
    TWEAKS_APPS="['org.gnome.tweaks.desktop', 'com.mattjakeman.ExtensionManager.desktop']"
    apply_dconf_setting "/org/gnome/shell/extensions/tweaks-system-menu/applications" "$TWEAKS_APPS" "Tweaksシステムメニューアプリ"
    
    log_success "🎉 拡張機能設定の適用が完了しました！"
}

# キーバインド設定を適用する関数
apply_keybindings() {
    log_info "⌨️ キーバインド設定を適用中..."
    
    # Shell全般のキーバインド
    apply_dconf_setting "/org/gnome/shell/keybindings/toggle-message-tray" "@as []" "メッセージトレイトグル無効"
    apply_dconf_setting "/org/gnome/shell/keybindings/toggle-overview" "['<Primary><Alt>Tab']" "オーバービュートグル"
    
    log_success "🎉 キーバインド設定の適用が完了しました！"
}

# バックアップ作成関数
create_backup() {
    local backup_dir
    backup_dir="$HOME/.config/gnome-settings-backup-$(date +%Y%m%d_%H%M%S)"
    log_info "💾 現在の設定をバックアップ中: $backup_dir"
    
    mkdir -p "$backup_dir"
    
    # 主要な設定をバックアップ
    dconf dump /org/gnome/desktop/ > "$backup_dir/desktop.dconf" 2>/dev/null || true
    dconf dump /org/gnome/shell/ > "$backup_dir/shell.dconf" 2>/dev/null || true
    dconf dump /org/gnome/mutter/ > "$backup_dir/mutter.dconf" 2>/dev/null || true
    
    log_success "バックアップが完了しました: $backup_dir"
}

# 設定復元関数
restore_from_backup() {
    local backup_dir="$1"
    
    if [ ! -d "$backup_dir" ]; then
        log_error "バックアップディレクトリが見つかりません: $backup_dir"
        return 1
    fi
    
    log_info "📥 設定を復元中: $backup_dir"
    
    if [ -f "$backup_dir/desktop.dconf" ]; then
        if dconf load /org/gnome/desktop/ < "$backup_dir/desktop.dconf" 2>/dev/null; then
            log_success "デスクトップ設定を復元しました"
        else
            log_error "デスクトップ設定の復元に失敗しました"
        fi
    fi
    
    if [ -f "$backup_dir/shell.dconf" ]; then
        if dconf load /org/gnome/shell/ < "$backup_dir/shell.dconf" 2>/dev/null; then
            log_success "シェル設定を復元しました"
        else
            log_error "シェル設定の復元に失敗しました"
        fi
    fi
    
    if [ -f "$backup_dir/mutter.dconf" ]; then
        if dconf load /org/gnome/mutter/ < "$backup_dir/mutter.dconf" 2>/dev/null; then
            log_success "Mutter設定を復元しました"
        else
            log_error "Mutter設定の復元に失敗しました"
        fi
    fi
    
    log_success "🎉 設定の復元処理が完了しました"
}

# 現在の設定をエクスポートする関数
export_current_settings() {
    local export_dir
    export_dir="gnome-settings-export-$(date +%Y%m%d_%H%M%S)"
    
    log_info "📤 現在の設定をエクスポート中: $export_dir"
    
    mkdir -p "$export_dir"
    
    # 設定をエクスポート
    dconf dump /org/gnome/desktop/ > "$export_dir/desktop.dconf"
    dconf dump /org/gnome/shell/ > "$export_dir/shell.dconf"
    dconf dump /org/gnome/mutter/ > "$export_dir/mutter.dconf"
    
    # 説明ファイルを作成
    cat > "$export_dir/README.md" << EOF
# GNOME設定エクスポート

エクスポート日時: $(date)

## ファイル説明
- \`desktop.dconf\`: デスクトップ設定（テーマ、フォント、キーボード等）
- \`shell.dconf\`: GNOME Shell設定（拡張機能、お気に入りアプリ等）
- \`mutter.dconf\`: Mutter設定（ワークスペース、ウィンドウマネージャー等）

## 復元方法
\`\`\`bash
dconf load /org/gnome/desktop/ < desktop.dconf
dconf load /org/gnome/shell/ < shell.dconf
dconf load /org/gnome/mutter/ < mutter.dconf
\`\`\`

または:
\`\`\`bash
./setup-gnome-tweaks.sh --restore $export_dir
\`\`\`
EOF
    
    log_success "エクスポートが完了しました: $export_dir"
    echo "📁 エクスポートディレクトリ: $(pwd)/$export_dir"
}

# GNOME Shell再起動関数
restart_gnome_shell() {
    log_info "🔄 GNOME Shellを再起動中..."
    
    local session_type="${XDG_SESSION_TYPE:-x11}"
    if [ "$session_type" = "wayland" ]; then
        log_warning "Wayland環境ではGNOME Shellの再起動ができません"
        log_info "ログアウト・ログインして設定を反映してください"
    else
        # X11環境の場合
        if command -v gnome-shell >/dev/null 2>&1; then
            busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting…")' 2>/dev/null || {
                log_warning "GNOME Shell再起動に失敗しました"
                log_info "Alt+F2 を押して 'r' を入力して再起動してください"
            }
        fi
    fi
}

# メイン関数
main() {
    echo -e "${BLUE}"
    cat << 'EOF'
  ____                            _____                    _        
 / ___|_ __   ___  _ __ ___   ___|_   _|_      _____  __ _| | _____ 
| |  _| '_ \ / _ \| '_ ` _ \ / _ \ | | \ \ /\ / / _ \/ _` | |/ / __|
| |_| | | | | (_) | | | | | |  __/ | |  \ V  V /  __/ (_| |   <\__ \
 \____|_| |_|\___/|_| |_| |_|\___| |_|   \_/\_/ \___|\__,_|_|\_\___/

              設定復元スクリプト v1.0
EOF
    echo -e "${NC}"
    
    case "${1:-}" in
        --backup)
            create_backup
            ;;
        --restore)
            if [ -z "${2:-}" ]; then
                log_error "復元するディレクトリを指定してください"
                echo "使用例: $0 --restore /path/to/backup"
                exit 1
            fi
            restore_from_backup "$2"
            ;;
        --export)
            export_current_settings
            ;;
        --apply-extensions-only)
            apply_extension_settings
            ;;
        --apply-keybindings-only)
            apply_keybindings
            ;;
        --no-restart)
            apply_gnome_tweaks_settings
            apply_extension_settings
            apply_keybindings
            log_info "🔄 GNOME Shell再起動をスキップしました"
            ;;
        --help|-h)
            echo "使用方法: $0 [オプション]"
            echo ""
            echo "オプション:"
            echo "  (なし)                     全設定を適用してGNOME Shellを再起動"
            echo "  --backup                   現在の設定をバックアップ"
            echo "  --restore <dir>            指定したディレクトリから設定を復元"
            echo "  --export                   現在の設定をエクスポート"
            echo "  --apply-extensions-only    拡張機能設定のみ適用"
            echo "  --apply-keybindings-only   キーバインド設定のみ適用"
            echo "  --no-restart               GNOME Shell再起動をスキップ"
            echo "  --help, -h                 このヘルプを表示"
            exit 0
            ;;
        "")
            # デフォルト: 全設定適用
            create_backup
            apply_gnome_tweaks_settings
            apply_extension_settings
            apply_keybindings
            
            echo ""
            log_info "🔄 設定を反映するため、以下のいずれかを実行してください:"
            echo "1. ログアウト・ログイン"
            echo "2. Alt+F2 を押して 'r' を入力（X11のみ）"
            echo "3. システム再起動"
            
            read -r -p "GNOME Shellを今すぐ再起動しますか？ (y/N): " -n 1
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                restart_gnome_shell
            fi
            ;;
        *)
            log_error "不明なオプション: $1"
            echo "ヘルプを表示するには: $0 --help"
            exit 1
            ;;
    esac
    
    echo ""
    log_success "🎉 処理が完了しました！"
}

# エラーハンドリング
trap 'log_error "スクリプト実行中にエラーが発生しました"' ERR

# スクリプト実行
main "$@" 