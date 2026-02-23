# SHIFTキー固定モード対策関連のターゲット

.PHONY: setup-sticky-keys
setup-sticky-keys: ## SHIFTキー固定モード対策をセットアップ
	@echo "🔧 SHIFTキー固定モード対策をセットアップ中..."
	@bash sticky-keys/install.sh
	@echo "✅ SHIFTキー固定モード対策のセットアップが完了しました"

.PHONY: fix-sticky-keys
fix-sticky-keys: ## SHIFTキー固定モードを即座に解除
	@echo "🛠️ SHIFTキー固定モードを解除中..."
	@if [ -f ""$(HOME)/.local/bin/fix-sticky-keys-instant.sh"" ]; then \
		"$(HOME)/.local/bin/fix-sticky-keys-instant.sh"; \
	else \
		echo "❌ fix-sticky-keys-instant.sh が見つかりません。先に 'make setup-sticky-keys' を実行してください。"; \
		exit 1; \
	fi

.PHONY: disable-sticky-keys
disable-sticky-keys: ## SHIFTキー固定モードを無効化
	@echo "⚙️ SHIFTキー固定モードを無効化中..."
	@if [ -f ""$(HOME)/.local/bin/disable-sticky-keys.sh"" ]; then \
		"$(HOME)/.local/bin/disable-sticky-keys.sh"; \
	else \
		echo "❌ disable-sticky-keys.sh が見つかりません。先に 'make setup-sticky-keys' を実行してください。"; \
		exit 1; \
	fi

.PHONY: sticky-keys-status
sticky-keys-status: ## SHIFTキー固定モードの現在の状態を確認
	@echo "📊 SHIFTキー固定モード設定状況:"
	@echo "stickykeys-enable: $$(gsettings get org.gnome.desktop.a11y.keyboard stickykeys-enable)"
	@echo "stickykeys-two-key-off: $$(gsettings get org.gnome.desktop.a11y.keyboard stickykeys-two-key-off)"
	@echo "stickykeys-modifier-beep: $$(gsettings get org.gnome.desktop.a11y.keyboard stickykeys-modifier-beep)"
	@echo "always-show-universal-access-status: $$(gsettings get org.gnome.desktop.a11y always-show-universal-access-status)"
	@echo ""
	@echo "📁 インストール状況:"
	@if [ -f ""$(HOME)/.local/bin/fix-sticky-keys-instant.sh"" ]; then \
		echo "✅ 即座解除スクリプト: インストール済み"; \
	else \
		echo "❌ 即座解除スクリプト: 未インストール"; \
	fi
	@if [ -f ""$(HOME)/.config/autostart/disable-sticky-keys.desktop"" ]; then \
		echo "✅ 自動起動設定: インストール済み"; \
	else \
		echo "❌ 自動起動設定: 未インストール"; \
	fi
	@if [ -f ""$(HOME)/Desktop/Fix-Sticky-Keys.desktop"" ]; then \
		echo "✅ デスクトップショートカット: インストール済み"; \
	else \
		echo "❌ デスクトップショートカット: 未インストール"; \
	fi

.PHONY: uninstall-sticky-keys
uninstall-sticky-keys: ## SHIFTキー固定モード対策をアンインストール
	@echo "🗑️ SHIFTキー固定モード対策をアンインストール中..."
	@rm -f "$(HOME)/.local/bin/fix-sticky-keys-instant.sh"
	@rm -f "$(HOME)/.local/bin/disable-sticky-keys.sh"
	@rm -f "$(HOME)/.config/autostart/disable-sticky-keys.desktop"
	@rm -f "$(HOME)/Desktop/Fix-Sticky-Keys.desktop"
	@echo "🔧 カスタムキーバインドを削除中..."
	@{ \
	  SCHEMA="org.gnome.settings-daemon.plugins.media-keys"; \
	  KEY="custom-keybindings"; \
	  TARGET="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/fix-sticky-keys/"; \
	  EXISTING=$$(gsettings get $$SCHEMA $$KEY | sed 's/^@as //'); \
	  if echo "$$EXISTING" | grep -Fq "$$TARGET"; then \
	    PRUNED=$$(python3 - "$$EXISTING" "$$TARGET" <<'PY' \
import ast, sys \
lst = ast.literal_eval(sys.argv[1]) \
target = sys.argv[2] \
lst = [x for x in lst if x != target] \
print("[" + ",".join(f"'{x}'" for x in lst) + "]") \
PY \
); \
	    gsettings set $$SCHEMA $$KEY "$$PRUNED"; \
	  fi; \
	  gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$$TARGET name 2>/dev/null || true; \
	  gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$$TARGET command 2>/dev/null || true; \
	  gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$$TARGET binding 2>/dev/null || true; \
	}
	@echo "✅ SHIFTキー固定モード対策のアンインストールが完了しました"

.PHONY: sticky-keys-menu
sticky-keys-menu: ## SHIFTキー固定モード対策メニューを表示
	@echo "┌─────────────────────────────────────────────────────────┐"
	@echo "│            ⌨️  SHIFTキー固定モード対策メニュー            │"
	@echo "├─────────────────────────────────────────────────────────┤"
	@echo "│ 1) 対策ツールをインストール・設定                       │"
	@echo "│ 2) SHIFTキー固定モードを即座に解除                      │"
	@echo "│ 3) SHIFTキー固定モードを無効化                          │"
	@echo "│ 4) 現在の設定状況を確認                                │"
	@echo "│ 5) 対策ツールをアンインストール                         │"
	@echo "│ 6) ヘルプを表示                                       │"
	@echo "│ 0) システム設定メニューに戻る                           │"
	@echo "└─────────────────────────────────────────────────────────┘"
	@echo ""
	@read -p "選択してください [0-6]: " choice; \
	case $$choice in \
		1) $(MAKE) setup-sticky-keys ;; \
		2) $(MAKE) fix-sticky-keys ;; \
		3) $(MAKE) disable-sticky-keys ;; \
		4) $(MAKE) sticky-keys-status ;; \
		5) $(MAKE) uninstall-sticky-keys ;; \
		6) $(MAKE) sticky-keys-help ;; \
		0) $(MAKE) sys ;; \
		*) echo "❌ 無効な選択です"; $(MAKE) sticky-keys-menu ;; \
	esac

.PHONY: sticky-keys-help
sticky-keys-help: ## SHIFTキー固定モード対策のヘルプを表示
	@echo "🔧 SHIFTキー固定モード対策 - 使用可能なコマンド:"
	@echo ""
	@echo "📦 インストール・セットアップ:"
	@echo "  make setup-sticky-keys      - 対策ツールをインストール・設定"
	@echo "  make uninstall-sticky-keys  - 対策ツールをアンインストール"
	@echo ""
	@echo "🛠️ 実行・操作:"
	@echo "  make fix-sticky-keys        - SHIFTキー固定モードを即座に解除"
	@echo "  make disable-sticky-keys    - SHIFTキー固定モードを無効化"
	@echo ""
	@echo "📊 状態確認:"
	@echo "  make sticky-keys-status     - 現在の設定状況を確認"
	@echo "  make sticky-keys-help       - このヘルプを表示"
	@echo ""
	@echo "💡 手動での解除方法:"
	@echo "  • ホットキー: Ctrl + Alt + S"
	@echo "  • 両SHIFTキー同時押し"
	@echo "  • デスクトップアイコンをダブルクリック"
	@echo "  • コマンド: ~/.local/bin/fix-sticky-keys-instant.sh"
