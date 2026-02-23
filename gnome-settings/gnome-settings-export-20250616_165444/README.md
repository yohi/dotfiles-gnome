# GNOME設定エクスポート

エクスポート日時: 2025年  6月 16日 月曜日 16:54:44 JST

## ファイル説明
- `desktop.dconf`: デスクトップ設定（テーマ、フォント、キーボード等）
- `shell.dconf`: GNOME Shell設定（拡張機能、お気に入りアプリ等）
- `mutter.dconf`: Mutter設定（ワークスペース、ウィンドウマネージャー等）

## 復元方法
```bash
dconf load /org/gnome/desktop/ < desktop.dconf
dconf load /org/gnome/shell/ < shell.dconf
dconf load /org/gnome/mutter/ < mutter.dconf
```

または:
```bash
./setup-gnome-tweaks.sh --restore gnome-settings-export-20250616_165444
```
