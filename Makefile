# Orchestrator core configuration
# Note: These are symlinked from ../../common-mk/ when managed by dotfiles-core
-include _mk/core.mk
-include _mk/help.mk

# Component-specific logic





REPO_ROOT ?= $(CURDIR)
include _mk/gnome.mk
include _mk/mozc.mk
include _mk/extensions.mk
include _mk/shortcuts.mk
include _mk/sticky-keys.mk

.PHONY: all
all: setup link

.PHONY: setup
setup: ## セットアップ（依存関係、設定適用）を一括実行します
	@echo "==> Setting up dotfiles-gnome"

.PHONY: link
link: ## シンボリックリンクを展開し、dotfiles を配置します
	@echo "==> Linking dotfiles-gnome"
	mkdir -p $(HOME)/.config/mozc
	ln -sfn $(REPO_ROOT)/dot-config/mozc/ibus_config.textproto $(HOME)/.config/mozc/ibus_config.textproto

.PHONY: clean
clean: ## 生成物や一時ファイルを削除します
	@echo "==> Cleaning up dotfiles-gnome"
	rm -f $(HOME)/.config/mozc/ibus_config.textproto

.PHONY: test
test:
	@echo "==> Testing dotfiles-gnome"
	@if [ ! -f "gnome-extensions/test-settings.sh" ]; then exit 0; else bash gnome-extensions/test-settings.sh; fi
