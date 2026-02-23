# GNOME キーボードショートカット設定

このディレクトリには、GNOME環境でのキーボードショートカット設定を保存します。

## 設定ファイル

- `wm-keybindings.dconf` - ウィンドウマネージャーのキーボードショートカット設定
- `media-keybindings.dconf` - メディアキーのキーボードショートカット設定
- `custom-keybindings.dconf` - カスタムキーボードショートカット設定
- `terminal-keybindings.dconf` - ターミナルのキーボードショートカット設定

## 現在の設定をエクスポートする方法

### システムキーバインドのエクスポート
```bash
# ウィンドウマネージャのキーバインド
dconf dump /org/gnome/desktop/wm/keybindings/ > gnome-shortcuts/wm-keybindings.dconf

# メディアキーのキーバインド
dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > gnome-shortcuts/media-keybindings.dconf

# カスタムキーバインド
dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ > gnome-shortcuts/custom-keybindings.dconf
```

### ターミナルショートカットのエクスポート
```bash
# GNOME Terminal（使用している場合）
dconf dump /org/gnome/terminal/legacy/keybindings/ > gnome-shortcuts/terminal-keybindings.dconf
```

## 設定をインポートする方法

```bash
# make setup-shortcuts コマンドで自動的に読み込まれます
make setup-shortcuts

# または手動で：
dconf load /org/gnome/desktop/wm/keybindings/ < gnome-shortcuts/wm-keybindings.dconf
dconf load /org/gnome/settings-daemon/plugins/media-keys/ < gnome-shortcuts/media-keybindings.dconf
dconf load /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ < gnome-shortcuts/custom-keybindings.dconf
```

## 設定例

よく使用されるキーボードショートカットの例：

- `Super+T` - ターミナルを開く
- `Super+E` - ファイルマネージャーを開く
- `Super+L` - 画面をロック
- `Ctrl+Alt+T` - ターミナルを開く（Ubuntu標準）
- `Alt+F2` - 実行ダイアログを開く

## 注意事項

- 設定を適用後は、一度ログアウト・ログインして設定を反映させることを推奨します
- 既存のショートカットと競合する場合は、設定が上書きされる可能性があります
- カスタムショートカットでは、実行するコマンドのフルパスを指定してください
