#!/bin/bash
# SHIFTキー固定モード対策のインストールスクリプト

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME}"

echo "🔧 SHIFTキー固定モード対策をインストール中..."

# ~/.local/binディレクトリを作成
mkdir -p "${HOME_DIR}/.local/bin"

# スクリプトをコピーして実行権限を付与
echo "📄 スクリプトファイルをコピー中..."
cp "${SCRIPT_DIR}/fix-sticky-keys-instant.sh" "${HOME_DIR}/.local/bin/"
cp "${SCRIPT_DIR}/disable-sticky-keys.sh" "${HOME_DIR}/.local/bin/"
chmod +x "${HOME_DIR}/.local/bin/fix-sticky-keys-instant.sh"
chmod +x "${HOME_DIR}/.local/bin/disable-sticky-keys.sh"

# 自動起動設定
echo "🚀 自動起動設定を構成中..."
mkdir -p "${HOME_DIR}/.config/autostart"
sed "s|HOME_DIR|${HOME_DIR}|g" "${SCRIPT_DIR}/disable-sticky-keys.desktop" > "${HOME_DIR}/.config/autostart/disable-sticky-keys.desktop"

# デスクトップショートカット
echo "🖥️ デスクトップショートカットを作成中..."
mkdir -p "${HOME_DIR}/Desktop"
sed "s|HOME_DIR|${HOME_DIR}|g" "${SCRIPT_DIR}/Fix-Sticky-Keys.desktop" > "${HOME_DIR}/Desktop/Fix-Sticky-Keys.desktop"
chmod +x "${HOME_DIR}/Desktop/Fix-Sticky-Keys.desktop"

# デスクトップファイルの信頼済みフラグを設定
gio set -t bool "${HOME_DIR}/Desktop/Fix-Sticky-Keys.desktop" metadata::trusted true 2>/dev/null || true

# ホットキー設定
echo "⌨️ ホットキー設定を構成中..."
# 既存のカスタムキーバインドを取得
existing_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

# 新しいパスを追加
new_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/fix-sticky-keys/"

# GVariant 先頭の型注釈 @as を除去して統一
bindings="${existing_bindings#@as }"
if [[ "$bindings" == "[]" ]]; then
  # 配列が空なら新規作成
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['${new_path}']"
elif grep -Fq "${new_path}" <<< "$bindings"; then
  # 既に登録済みなら何もしない
  echo "  (既にカスタムキーバインドに登録済み)"
else
  # 末尾の ] を取り除いて新要素を追記
  trimmed="${bindings%]}"
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${trimmed}, '${new_path}']"
fi

# キーバインドの詳細設定
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${new_path} name 'Fix Sticky Keys'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${new_path} command "${HOME_DIR}/.local/bin/fix-sticky-keys-instant.sh"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${new_path} binding '<Primary><Alt>s'

# 基本設定の適用
echo "⚙️ 基本設定を適用中..."
gsettings set org.gnome.desktop.a11y.keyboard stickykeys-enable false
gsettings set org.gnome.desktop.a11y.keyboard stickykeys-two-key-off true
gsettings set org.gnome.desktop.a11y.keyboard stickykeys-modifier-beep false
gsettings set org.gnome.desktop.a11y always-show-universal-access-status false

echo ""
echo "✅ SHIFTキー固定モード対策のインストールが完了しました！"
echo ""
echo "📋 使用方法:"
echo "  • ホットキー: Ctrl + Alt + S"
echo "  • 両SHIFTキー同時押し"
echo "  • デスクトップアイコンをダブルクリック"
echo "  • コマンド: ~/.local/bin/fix-sticky-keys-instant.sh"
echo ""
echo "🔄 自動起動も設定されているため、ログイン時に自動的に無効化されます。"
