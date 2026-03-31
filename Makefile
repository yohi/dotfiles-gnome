include _mk/core.mk
include _mk/help.mk
-include _mk/gnome.mk
-include _mk/mozc.mk
-include _mk/extensions.mk
-include _mk/shortcuts.mk
-include _mk/sticky-keys.mk

.PHONY: all install setup test clean
all: install setup ## インストールとセットアップを全て実行します

install: install-gnome ## GNOME 関連のインストール
setup: setup-gnome ## GNOME の設定適用

install-gnome:
	@echo "==> Installing dotfiles-gnome"

setup-gnome:
	@echo "==> Setting up dotfiles-gnome"
	mkdir -p $(HOME)/.config/mozc
	@if [ ! -f "$(DOTFILES_SHELL_ROOT)/dotfiles-gnome/dot-config/mozc/ibus_config.textproto" ]; then \
		echo "❌ Source file not found: $(DOTFILES_SHELL_ROOT)/dotfiles-gnome/dot-config/mozc/ibus_config.textproto"; \
		exit 1; \
	fi
	ln -sfn $(DOTFILES_SHELL_ROOT)/dotfiles-gnome/dot-config/mozc/ibus_config.textproto $(HOME)/.config/mozc/ibus_config.textproto

clean: ## 生成物や一時ファイルを削除します
	@echo "==> Cleaning up dotfiles-gnome"
	rm -f $(HOME)/.config/mozc/ibus_config.textproto

test: ## テスト実行
	@echo "==> Testing dotfiles-gnome"
	@if [ ! -f "gnome-extensions/test-settings.sh" ]; then exit 0; else bash gnome-extensions/test-settings.sh; fi
