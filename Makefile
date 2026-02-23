REPO_ROOT ?= $(CURDIR)
.DEFAULT_GOAL := setup
include _mk/gnome.mk
include _mk/mozc.mk
include _mk/extensions.mk
include _mk/shortcuts.mk
include _mk/sticky-keys.mk

.PHONY: setup
setup:
	@echo "==> Setting up dotfiles-gnome"

.PHONY: link
link:
	@echo "==> Linking dotfiles-gnome"
	mkdir -p $(HOME)/.config/mozc
	ln -sfn $(REPO_ROOT)/dot-config/mozc/ibus_config.textproto $(HOME)/.config/mozc/ibus_config.textproto
