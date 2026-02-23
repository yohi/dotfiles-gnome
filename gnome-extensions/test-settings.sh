#!/bin/bash

# Settings Application Test Script
set -euo pipefail

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to compare floating point numbers with tolerance
float_equals() {
    local val1="$1"
    local val2="$2"
    local epsilon="${3:-0.0001}"  # Default epsilon of 0.0001

    # Remove quotes if present
    val1=$(echo "$val1" | tr -d '"')
    val2=$(echo "$val2" | tr -d '"')

    # Check if values are empty or non-numeric
    if [ -z "$val1" ] || [ -z "$val2" ]; then
        return 1
    fi

    # Simple absolute difference check using shell arithmetic
    # Convert to integer by multiplying by 10000 for precision
    local int_val1=$(printf "%.0f" "$(echo "$val1 * 10000" | bc -l 2>/dev/null || echo "0")")
    local int_val2=$(printf "%.0f" "$(echo "$val2 * 10000" | bc -l 2>/dev/null || echo "0")")
    local int_epsilon=$(printf "%.0f" "$(echo "$epsilon * 10000" | bc -l 2>/dev/null || echo "1")")

    # Calculate absolute difference using shell arithmetic
    local diff=$((int_val1 - int_val2))
    diff=$((diff < 0 ? -diff : diff))

    # Compare difference with epsilon
    [ $diff -lt $int_epsilon ]
}

# Test specific extension settings
test_extension_settings() {
    echo "🧪 拡張機能設定テスト"
    echo "===================="

    log "Astra Monitor設定をテスト中..."

    # Test Astra Monitor settings
    local memory_percentage=$(dconf read /org/gnome/shell/extensions/astra-monitor/memory-header-percentage)
    local cpu_frequency=$(dconf read /org/gnome/shell/extensions/astra-monitor/processor-header-frequency)
    local cpu_percentage=$(dconf read /org/gnome/shell/extensions/astra-monitor/processor-header-percentage)

    if [ "$memory_percentage" = "true" ]; then
        success "✓ Astra Monitor: メモリパーセンテージ表示が有効"
    else
        error "✗ Astra Monitor: メモリパーセンテージ表示設定が正しくありません"
    fi

    if [ "$cpu_frequency" = "true" ]; then
        success "✓ Astra Monitor: CPU周波数表示が有効"
    else
        error "✗ Astra Monitor: CPU周波数表示設定が正しくありません"
    fi

    if [ "$cpu_percentage" = "true" ]; then
        success "✓ Astra Monitor: CPUパーセンテージ表示が有効"
    else
        error "✗ Astra Monitor: CPUパーセンテージ表示設定が正しくありません"
    fi

    log "Search Light設定をテスト中..."

    # Test Search Light settings
    local scale_width=$(dconf read /org/gnome/shell/extensions/search-light/scale-width)
    local scale_height=$(dconf read /org/gnome/shell/extensions/search-light/scale-height)
    local expected_scale="0.1"

    if float_equals "$scale_width" "$expected_scale"; then
        success "✓ Search Light: 幅スケール設定が正しく適用されています"
    else
        warning "⚠ Search Light: 幅スケール設定が期待値と異なります (現在値: $scale_width, 期待値: $expected_scale)"
    fi

    if float_equals "$scale_height" "$expected_scale"; then
        success "✓ Search Light: 高さスケール設定が正しく適用されています"
    else
        warning "⚠ Search Light: 高さスケール設定が期待値と異なります (現在値: $scale_height, 期待値: $expected_scale)"
    fi

    log "Bluetooth拡張機能設定をテスト中..."

    # Test Bluetooth settings
    local auto_power=$(dconf read /org/gnome/shell/extensions/bluetooth-quick-connect/bluetooth-auto-power-on)
    local show_battery=$(dconf read /org/gnome/shell/extensions/bluetooth_battery_indicator/show-battery-value-on)

    if [ "$auto_power" = "true" ]; then
        success "✓ Bluetooth Quick Connect: 自動電源オンが有効"
    else
        error "✗ Bluetooth Quick Connect: 自動電源オン設定が正しくありません"
    fi

    if [ "$show_battery" = "true" ]; then
        success "✓ Bluetooth Battery Indicator: バッテリー値表示が有効"
    else
        warning "⚠ Bluetooth Battery Indicator: バッテリー値表示設定を確認してください"
    fi
}

# Test settings backup and restore
test_settings_backup_restore() {
    echo ""
    echo "💾 設定バックアップ・復元テスト"
    echo "=============================="

    log "現在の設定をバックアップ中..."

    # Create backup directory
    local backup_dir="/tmp/gnome-ext-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Backup current settings
    dconf dump /org/gnome/shell/extensions/ > "$backup_dir/extensions-backup.dconf"

    if [ -f "$backup_dir/extensions-backup.dconf" ]; then
        success "✓ 設定のバックアップが完了しました: $backup_dir"
    else
        error "✗ 設定のバックアップに失敗しました"
        return 1
    fi

    log "設定ファイルのサイズを確認中..."
    local backup_size=$(wc -l < "$backup_dir/extensions-backup.dconf")
    local original_size=$(wc -l < "$SCRIPT_DIR/extensions-settings.dconf")

    echo "  - バックアップファイル: $backup_size 行"
    echo "  - オリジナルファイル: $original_size 行"

    if [ "$backup_size" -gt 10 ]; then
        success "✓ バックアップファイルに十分な設定データが含まれています"
    else
        warning "⚠ バックアップファイルのサイズが小さすぎる可能性があります"
    fi

    # Clean up
    rm -rf "$backup_dir"
    success "✓ 一時ファイルをクリーンアップしました"
}

# Test settings application from file
test_settings_application() {
    echo ""
    echo "⚙️ 設定ファイル適用テスト"
    echo "========================"

    log "保存された設定ファイルから設定を再適用中..."

    # Apply settings using the script
    if "$SCRIPT_DIR/install-extensions.sh" apply-settings >/dev/null 2>&1; then
        success "✓ 設定の再適用が成功しました"
    else
        error "✗ 設定の再適用に失敗しました"
        return 1
    fi

    # Wait a moment for settings to take effect
    sleep 2

    # Verify some key settings are still applied
    local memory_percentage=$(dconf read /org/gnome/shell/extensions/astra-monitor/memory-header-percentage)
    if [ "$memory_percentage" = "true" ]; then
        success "✓ 設定の再適用後も設定が保持されています"
    else
        warning "⚠ 設定の再適用後に一部設定が失われた可能性があります"
    fi
}

# Main test execution
main() {
    echo "🔧 GNOME Extensions 設定自動反映テスト"
    echo "======================================"
    echo ""

    # Test 1: Extension settings verification
    test_extension_settings

    # Test 2: Settings backup and restore
    test_settings_backup_restore

    # Test 3: Settings application from file
    test_settings_application

    echo ""
    echo "📊 テスト結果サマリー"
    echo "==================="

    # Count enabled extensions
    local enabled_count=$(gnome-extensions list --enabled | wc -l)
    echo "  - 有効化された拡張機能: $enabled_count 個"

    # Check if critical extensions are enabled
    local critical_extensions=("monitor@astraext.github.io" "search-light@icedman.github.com" "bluetooth-battery@michalw.github.com" "bluetooth-quick-connect@bjarosze.gmail.com")
    local enabled_critical=0

    for ext in "${critical_extensions[@]}"; do
        if gnome-extensions list --enabled | grep -q "$ext"; then
            ((enabled_critical++))
        fi
    done

    echo "  - 重要な拡張機能の有効化: $enabled_critical/${#critical_extensions[@]} 個"

    if [ "$enabled_critical" -eq "${#critical_extensions[@]}" ]; then
        success "✓ 全ての重要な拡張機能が有効化されています"
    else
        warning "⚠ 一部の重要な拡張機能が有効化されていません"
    fi

    echo ""
    success "🎉 設定自動反映テストが完了しました！"
    echo ""
    echo "💡 確認事項："
    echo "  - パネルに新しいアイコンが表示されていることを確認してください"
    echo "  - 各拡張機能が正常に動作していることを確認してください"
    echo "  - 設定が期待通りに適用されていることを確認してください"
    echo ""
    echo "⚠️ 注意: ログアウト直前で停止してください"
}

# Execute main function
main "$@"
