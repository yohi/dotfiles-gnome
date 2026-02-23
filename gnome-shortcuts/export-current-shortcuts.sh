#!/bin/bash
set -euo pipefail

# GNOME キーボードショートカット設定エクスポート用スクリプト
# 現在の設定をdconfファイルとして保存します

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔧 現在のGNOMEキーボードショートカット設定をエクスポート中..."

# ウィンドウマネージャのキーバインド
echo "🪟 ウィンドウマネージャのキーバインドをエクスポート中..."
dconf dump /org/gnome/desktop/wm/keybindings/ > "$SCRIPT_DIR/wm-keybindings.dconf"
echo "✅ 保存先: $SCRIPT_DIR/wm-keybindings.dconf"

# メディアキーのキーバインド
echo "🎵 メディアキーのキーバインドをエクスポート中..."
dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > "$SCRIPT_DIR/media-keybindings.dconf"
echo "✅ 保存先: $SCRIPT_DIR/media-keybindings.dconf"

# カスタムキーバインド
echo "🔧 カスタムキーバインドをエクスポート中..."
dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ > "$SCRIPT_DIR/custom-keybindings.dconf"
echo "✅ 保存先: $SCRIPT_DIR/custom-keybindings.dconf"

# ターミナルキーバインド（GNOME Terminal）
if dconf list /org/gnome/terminal/legacy/keybindings/ >/dev/null 2>&1; then
    echo "🖥️  ターミナルキーバインドをエクスポート中..."
    dconf dump /org/gnome/terminal/legacy/keybindings/ > "$SCRIPT_DIR/terminal-keybindings.dconf"
    echo "✅ 保存先: $SCRIPT_DIR/terminal-keybindings.dconf"
else
    echo "ℹ️  GNOME Terminalのキーバインド設定が見つかりませんでした"
fi

echo ""
echo "🎉 キーボードショートカット設定のエクスポートが完了しました！"
echo ""
echo "📋 エクスポートされたファイル:"
ls -la "$SCRIPT_DIR"/*.dconf 2>/dev/null || echo "  設定ファイルが見つかりませんでした"
echo ""
echo "💡 これらの設定を適用するには:"
echo "   make setup-shortcuts"
