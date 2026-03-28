# dotfiles-gnome

GNOMEデスクトップ環境の設定と拡張機能（Extensions、キーマップ、ショートカットなど）を管理するコンポーネントリポジトリです。
`dotfiles-core` と連携して動作します。

## 主要機能

- **GNOME Extensions**: 拡張機能の一括インストールと管理。
- **デスクトップ設定**: dconf による詳細な外観・挙動設定。
- **キーボードショートカット**: 開発効率を高めるカスタムショートカット。
- **日本語入力**: Mozc (IBus) の環境設定。
- **アクセシビリティ**: 固定キー機能の自動設定。

## 管理と依存関係

本リポジトリは [dotfiles-core](https://github.com/yohi/dotfiles-core) によって管理されるコンポーネントの 一つです。

### ⚠️ 単体使用時の注意点
本リポジトリは `dotfiles-core` の共通 Makefile ルール（`common-mk`）に依存しています。単体で使用（クローン）する場合は、以下の手順が必要です：

1. `common-mk` ディレクトリを本リポジトリの親ディレクトリに配置するか、パスを適切に設定してください。
2. `make help` を実行して、正しく設定されていることを確認してください。

推奨される使用方法は、`dotfiles-core` から `make setup` を実行することです。

## ディレクトリ構成

```text
.
├── Makefile
├── README.md
├── AGENTS.md
├── _mk/                    # Makefile sub-targets
├── dot-config/             # Config file templates
├── gnome-extensions/       # GNOME Extensions management
├── gnome-settings/         # dconf settings
├── gnome-shortcuts/        # Custom keyboard shortcuts
├── mozc/                   # Mozc (Japanese Input) configuration
└── sticky-keys/            # Accessibility settings
```
