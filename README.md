# dotfiles-gnome

GNOMEデスクトップ環境の設定と拡張機能（Extensions、キーマップ、ショートカットなど）を管理するコンポーネントリポジトリです。
`dotfiles-core` と連携して動作します。



## ⚠️  Standalone Usage Note
This repository depends on common Makefile fragments and rules from [dotfiles-core](https://github.com/yohi/dotfiles-core).
When using this repository standalone, you must manually set up the `common-mk` dependency:

1. Clone or copy the `common-mk` directory from the [dotfiles-core](https://github.com/yohi/dotfiles-core) repository.
2. Place it such that it's available at `../common-mk/` relative to this repository root.

Alternatively, use `dotfiles-core` to manage the entire setup automatically via `make setup`.
