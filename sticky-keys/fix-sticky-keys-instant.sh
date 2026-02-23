#!/bin/bash
# SHIFTキー固定モードを即座に解除（ログアウト不要）
set -euo pipefail

echo "=== SHIFTキー固定モード解除中 ==="

# 1. GSettings経由で設定を無効化
gsettings set org.gnome.desktop.a11y.keyboard stickykeys-enable false

# 2. dconf経由で直接設定
dconf write /org/gnome/desktop/a11y/keyboard/stickykeys-enable false

# 3. キーボード入力をリセット（X11/XWaylandのみ。ユーザーのレイアウトは維持）
if [ "${XDG_SESSION_TYPE:-}" = "x11" ] || [ -n "${DISPLAY:-}" ]; then
    setxkbmap -option '' 2>/dev/null || true
fi

# 5. GNOME Settings Daemonのキーボードサービスにリセット信号を送信
gdbus call --session --dest org.gnome.SettingsDaemon.Keyboard \
    --object-path /org/gnome/SettingsDaemon/Keyboard \
    --method org.gnome.SettingsDaemon.Keyboard.Reset 2>/dev/null || true

# 6. 現在の状態を確認
current_state=$(gsettings get org.gnome.desktop.a11y.keyboard stickykeys-enable)
echo "Sticky Keys状態: $current_state"

if [ "$current_state" = "false" ]; then
    echo "✅ SHIFTキー固定モードが正常に解除されました"

    # 通知を表示
    notify-send "キーボード" "SHIFTキー固定モードが解除されました" --urgency=normal --expire-time=3000 2>/dev/null || true
else
    echo "❌ 解除に失敗しました。手動で確認が必要です"
    notify-send "キーボード" "SHIFTキー固定モード解除に失敗" --urgency=critical 2>/dev/null || true
fi

echo "=== 完了 ==="
