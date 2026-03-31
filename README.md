# dotfiles-gnome

GNOMEデスクトップ環境の設定と拡張機能（Extensions、キーマップ、ショートカットなど）を管理するコンポーネントリポジトリです。

## 管理と共存関係

> [!IMPORTANT]
> 本リポジトリは [dotfiles-core](https://github.com/yohi/dotfiles) によって管理されるコンポーネントの一つです。

> [!WARNING]
> **使用時の注意点**
> 本リポジトリは `dotfiles-core` の共通 Makefile ルール（`common-mk`）に依存しており、実行時には `common-mk` へのシンボリックリンクが必要です。そのため、**本リポジトリ単体での使用（クローンしての利用）はサポートされていません。**
>
> 推奨される使用方法は、`dotfiles-core` リポジトリから `make setup` を実行し、適切なディレクトリ構造とシンボリックリンクが構成された状態で利用することです。

## 主要機能

- **GNOME Extensions**: 拡張機能の一括インストールと管理。
- **デスクトップ設定**: dconf による詳細な外観・挙動設定。
- **キーボードショートカット**: 開発効率を高めるカスタムショートカット。
- **日本語入力**: Mozc (IBus) の環境設定。
- **アクセシビリティ**: 固定キー機能の自動設定。

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
