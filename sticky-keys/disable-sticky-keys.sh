#!/bin/bash
set -euo pipefail
# SHIFTキー固定モードを確実に無効化するスクリプト

# ログディレクトリの作成とログファイル設定
mkdir -p "${HOME}/.config"
LOG="${HOME}/.config/sticky-keys-disable.log"

# GSettings経由での無効化
gsettings set org.gnome.desktop.a11y.keyboard stickykeys-enable false
gsettings set org.gnome.desktop.a11y.keyboard stickykeys-two-key-off true
gsettings set org.gnome.desktop.a11y.keyboard stickykeys-modifier-beep false
gsettings set org.gnome.desktop.a11y always-show-universal-access-status false

# dconf経由での確実な無効化
dconf write /org/gnome/desktop/a11y/keyboard/stickykeys-enable false

# 設定の確認とログ出力
{
    echo "Sticky Keys設定状況:"
    echo "stickykeys-enable: $(gsettings get org.gnome.desktop.a11y.keyboard stickykeys-enable)"
    echo "stickykeys-two-key-off: $(gsettings get org.gnome.desktop.a11y.keyboard stickykeys-two-key-off)"
    echo "$(date): Sticky Keys無効化完了"
} | tee -a "${LOG}"
