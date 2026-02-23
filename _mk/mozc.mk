# Mozc関連のターゲット

# Mozc辞書の設定変数
MOZC_DICT_VERSION := 20240330
MOZC_DICT_FILENAME := mozcdic-ut-$(MOZC_DICT_VERSION).zip
MOZC_DICT_URL := https://github.com/utuhiro78/mozcdic-ut/releases/download/$(MOZC_DICT_VERSION)/$(MOZC_DICT_FILENAME)
MOZC_DICT_CHECKSUM := 0000000000000000000000000000000000000000000000000000000000000000  # 実際のSHA256チェックサム。0または空の場合は検証をスキップします
MOZC_DICT_TXT := mozcdic-ut-$(MOZC_DICT_VERSION).txt
MOZC_CONFIG_DIR := $(HOME_DIR)/.config/mozc
MOZC_DOTFILES_CONFIG_DIR := $(DOTFILES_SHELL_ROOT)/dotfiles-gnome/mozc

# Fcitx5 Mozcの設定
setup-fcitx5-mozc:
	@echo "⌨️  Fcitx5 Mozcの設定を実行中..."

	# Mozcのインストール
	@echo "📦 Mozcをインストール中..."
	@sudo DEBIAN_FRONTEND=noninteractive apt-get install -y fcitx5-mozc mozc-utils-gui || true

	# Fcitx5の設定
	@echo "🔧 Fcitx5を設定中..."
	@sudo DEBIAN_FRONTEND=noninteractive apt-get install -y fcitx5 fcitx5-config-qt || true

	# 環境変数の設定
	@echo "🌍 環境変数を設定中..."
	@if ! grep -q "GTK_IM_MODULE=fcitx" $(HOME_DIR)/.profile 2>/dev/null; then \
		echo "export GTK_IM_MODULE=fcitx" >> $(HOME_DIR)/.profile; \
	fi
	@if ! grep -q "QT_IM_MODULE=fcitx" $(HOME_DIR)/.profile 2>/dev/null; then \
		echo "export QT_IM_MODULE=fcitx" >> $(HOME_DIR)/.profile; \
	fi
	@if ! grep -q "XMODIFIERS=@im=fcitx" $(HOME_DIR)/.profile 2>/dev/null; then \
		echo "export XMODIFIERS=@im=fcitx" >> $(HOME_DIR)/.profile; \
	fi

	# Fcitx5の自動起動設定
	@echo "🚀 Fcitx5の自動起動を設定中..."
	@mkdir -p $(HOME_DIR)/.config/autostart
	@if [ ! -f "$(HOME_DIR)/.config/autostart/fcitx5.desktop" ]; then \
		echo "[Desktop Entry]" > $(HOME_DIR)/.config/autostart/fcitx5.desktop; \
		echo "Type=Application" >> $(HOME_DIR)/.config/autostart/fcitx5.desktop; \
		echo "Exec=fcitx5" >> $(HOME_DIR)/.config/autostart/fcitx5.desktop; \
		echo "Hidden=false" >> $(HOME_DIR)/.config/autostart/fcitx5.desktop; \
		echo "NoDisplay=false" >> $(HOME_DIR)/.config/autostart/fcitx5.desktop; \
		echo "X-GNOME-Autostart-enabled=true" >> $(HOME_DIR)/.config/autostart/fcitx5.desktop; \
		echo "Name=Fcitx5" >> $(HOME_DIR)/.config/autostart/fcitx5.desktop; \
		echo "Comment=Start Fcitx5 Input Method" >> $(HOME_DIR)/.config/autostart/fcitx5.desktop; \
	fi
	@echo "✅ Fcitx5 Mozcの設定が完了しました。"
	@echo "ℹ️  ログアウト・ログインしてからMozcを使用してください。"

# Mozc一本化（Mac風）スタイル + Ctrl+Space切り替えを自動構築するターゲット (IBus)
setup-mozc:
	@echo "1. Installing Mozc..."
	sudo apt install -y ibus-mozc mozc-utils-gui

	@echo "2. Setting Input Source to Mozc ONLY..."
	# 入力ソースを「Mozc」のみにします（これでOSの切り替え機能と決別します）
	# ※万が一のために 'xkb','jp' (標準日本語) も末尾に残しますが、先頭はMozcにします
	gsettings set org.gnome.desktop.input-sources sources "[('ibus', 'mozc-jp'), ('xkb', 'jp')]"
	gsettings set org.gnome.desktop.input-sources mru-sources "[('ibus', 'mozc-jp'), ('xkb', 'jp')]"
	gsettings set org.gnome.desktop.input-sources current 0
	# 入力ソースインジケーターを表示する設定
	gsettings set org.gnome.desktop.input-sources show-all-sources true

	@echo "3. Configuring environment variables..."
	# IBus用の環境変数を.profileに設定
	@if ! grep -q "GTK_IM_MODULE=ibus" $(HOME_DIR)/.profile 2>/dev/null; then \
		echo "export GTK_IM_MODULE=ibus" >> $(HOME_DIR)/.profile; \
	fi
	@if ! grep -q "QT_IM_MODULE=ibus" $(HOME_DIR)/.profile 2>/dev/null; then \
		echo "export QT_IM_MODULE=ibus" >> $(HOME_DIR)/.profile; \
	fi
	@if ! grep -q "XMODIFIERS=@im=ibus" $(HOME_DIR)/.profile 2>/dev/null; then \
		echo "export XMODIFIERS=@im=ibus" >> $(HOME_DIR)/.profile; \
	fi
	@if ! grep -q "IBUS_USE_PORTAL=1" $(HOME_DIR)/.profile 2>/dev/null; then \
		echo "export IBUS_USE_PORTAL=1" >> $(HOME_DIR)/.profile; \
	fi

	@echo "4. Configuring IBus shortcuts..."
	# OS側の Ctrl+Space を無効化（Mozcに直接キーを届けるため）
	gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"
	gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"
	# IBusの設定ディレクトリを作成
	@mkdir -p $(HOME_DIR)/.config/ibus
	@mkdir -p $(HOME_DIR)/.config/ibus/bus

	@echo "5. Configuring Mozc (Hiragana default & Keymap) using symbolic links..."
	mkdir -p $(MOZC_CONFIG_DIR)

	# 設定ファイル(ibus_config.textproto)を作成
	# active_on_launch: True (起動時ひらがな)
	# notification_on_mode_change: True (切り替え時にUIを表示)
	# keymap_style: カスタムキーマップファイルが存在する場合は "custom"、存在しない場合は "default"
	@if [ -f "$(MOZC_DOTFILES_CONFIG_DIR)/my_keymap.txt" ]; then \
		echo "active_on_launch: True" > $(MOZC_CONFIG_DIR)/ibus_config.textproto; \
		echo "keymap_style: \"custom\"" >> $(MOZC_CONFIG_DIR)/ibus_config.textproto; \
		echo "notification_on_mode_change: True" >> $(MOZC_CONFIG_DIR)/ibus_config.textproto; \
		echo "✅ カスタムキーマップを使用します"; \
	else \
		echo "active_on_launch: True" > $(MOZC_CONFIG_DIR)/ibus_config.textproto; \
		echo "keymap_style: \"default\"" >> $(MOZC_CONFIG_DIR)/ibus_config.textproto; \
		echo "notification_on_mode_change: True" >> $(MOZC_CONFIG_DIR)/ibus_config.textproto; \
		echo "📝 デフォルトキーマップを使用します（Ctrl+SpaceでIME切り替え）"; \
	fi

	# キーマップファイルの設定（カスタムキーマップが存在する場合のみ）
	@if [ -f "$(MOZC_DOTFILES_CONFIG_DIR)/my_keymap.txt" ]; then \
		ln -sf $(MOZC_DOTFILES_CONFIG_DIR)/my_keymap.txt $(MOZC_CONFIG_DIR)/user_keymap.txt; \
		echo "✅ カスタムキーマップファイルを適用しました"; \
	fi

	@echo "6. Configuring IBus indicator display..."
	# IBusのインジケーター表示設定（切り替え時にUIを表示）
	@gsettings set org.gnome.desktop.input-sources show-all-sources true
	@gsettings set org.gnome.desktop.input-sources per-window false

	@echo "7. Setting up IBus autostart..."
	# IBusの自動起動設定
	@mkdir -p $(HOME_DIR)/.config/autostart
	@if [ ! -f "$(HOME_DIR)/.config/autostart/ibus.desktop" ]; then \
		echo "[Desktop Entry]" > $(HOME_DIR)/.config/autostart/ibus.desktop; \
		echo "Type=Application" >> $(HOME_DIR)/.config/autostart/ibus.desktop; \
		echo "Name=IBus" >> $(HOME_DIR)/.config/autostart/ibus.desktop; \
		echo "Comment=Start IBus input method framework" >> $(HOME_DIR)/.config/autostart/ibus.desktop; \
		echo "Exec=ibus-daemon -drx" >> $(HOME_DIR)/.config/autostart/ibus.desktop; \
		echo "Icon=ibus" >> $(HOME_DIR)/.config/autostart/ibus.desktop; \
		echo "X-GNOME-Autostart-enabled=true" >> $(HOME_DIR)/.config/autostart/ibus.desktop; \
	fi

	@echo "8. Restarting IBus..."
	# 設定反映（現在のセッションでも有効にするため）
	@pkill -f '[i]bus-daemon' || true
	@sleep 2
	@export GTK_IM_MODULE=ibus QT_IM_MODULE=ibus XMODIFIERS=@im=ibus IBUS_USE_PORTAL=1 && \
		ibus-daemon -drx &
	@ibus engine mozc-jp >/dev/null 2>&1 || true

	@echo ""
	@echo "✅ セットアップ完了！"
	@echo "   - Ctrl+Space 1回で日本語入力と直接入力を切り替え"
	@echo "   - 切り替え時に画面上にUIが表示されます"
	@echo "   - 日本語入力の初期値はひらがなです"
	@echo ""
	@echo "⚠️  重要: 以下のいずれかを実行してください："
	@echo "   1. 新しいターミナルを開く（環境変数を読み込むため）"
	@echo "   2. ログアウト・ログイン"
	@echo "   3. 以下のコマンドで環境変数を読み込む:"
	@echo "      source ~/.profile"
	@echo ""
	@echo "現在のセッションで即座に有効にする場合:"
	@echo "   export GTK_IM_MODULE=ibus QT_IM_MODULE=ibus XMODIFIERS=@im=ibus"

# Mozcキーマップのエクスポート
export-config-mozc-keymap: ## Mozcキーマップをエクスポート
	@echo "📋 現在のMozcキーマップをエクスポート中..."
	@mkdir -p $(MOZC_DOTFILES_CONFIG_DIR)
	/usr/lib/mozc/mozc_tool --mode=keymap_editor --export_file=$(MOZC_DOTFILES_CONFIG_DIR)/my_keymap.txt
	@echo "✅ キーマップが $(MOZC_DOTFILES_CONFIG_DIR)/my_keymap.txt にエクスポートされました。"
	@echo "ℹ️  このファイルをGitで管理してください。"


# Mozc UT辞書のセットアップ
setup-mozc-ut-dictionaries:
	@echo "📚 Mozc UT辞書をセットアップ中..."

	# 必要なパッケージのインストール
	@echo "📦 必要なパッケージをインストール中..."
	@if ! sudo DEBIAN_FRONTEND=noninteractive apt-get install -y wget unzip; then \
		echo "❌ エラー: 必要なパッケージのインストールに失敗しました"; \
		exit 1; \
	fi

	# 辞書ファイルのダウンロードとセットアップ
	@echo "⬇️  辞書ファイルをダウンロード中..."
	@mkdir -p $(MOZC_CONFIG_DIR)
	@cd $(MOZC_CONFIG_DIR) && \
	if [ ! -f "$(MOZC_DICT_FILENAME)" ]; then \
		if ! wget -O $(MOZC_DICT_FILENAME) "$(MOZC_DICT_URL)"; then \
			echo "❌ エラー: 辞書ファイルのダウンロードに失敗しました"; \
			exit 1; \
		fi; \
	fi

	# チェックサム検証
	@echo "🔍 ダウンロードしたファイルの整合性を検証中..."
	@cd $(MOZC_CONFIG_DIR) && \
	if [ -f "$(MOZC_DICT_FILENAME)" ]; then \
		ACTUAL_CHECKSUM=$$(sha256sum $(MOZC_DICT_FILENAME) | cut -d' ' -f1); \
		if [ -z "$(MOZC_DICT_CHECKSUM)" ] || echo "$(MOZC_DICT_CHECKSUM)" | grep -q "^0\+$$"; then \
			echo "⚠️  警告: チェックサム検証をスキップします（未設定またはプレースホルダー）"; \
			echo "実際値: $$ACTUAL_CHECKSUM"; \
		elif [ "$$ACTUAL_CHECKSUM" != "$(MOZC_DICT_CHECKSUM)" ]; then \
			echo "❌ エラー: チェックサムが一致しません"; \
			echo "期待値: $(MOZC_DICT_CHECKSUM)"; \
			echo "実際値: $$ACTUAL_CHECKSUM"; \
			echo "ファイルが破損している可能性があります。"; \
			rm -f $(MOZC_DICT_FILENAME); \
			exit 1; \
		else \
			echo "✅ チェックサム検証が成功しました"; \
		fi; \
	else \
		echo "❌ エラー: 辞書ファイルが見つかりません"; \
		exit 1; \
	fi

	# 辞書ファイルの展開
	@echo "📂 辞書ファイルを展開中..."
	@cd $(MOZC_CONFIG_DIR) && \
	if ! unzip -o $(MOZC_DICT_FILENAME); then \
		echo "❌ エラー: 辞書ファイルの展開に失敗しました"; \
		exit 1; \
	fi

	# 辞書のインポート
	@echo "📥 辞書をインポート中..."
	@if command -v /usr/lib/mozc/mozc_tool >/dev/null 2>&1; then \
		if ! /usr/lib/mozc/mozc_tool --mode=dictionary_tool --dictionary_import_file=$(MOZC_CONFIG_DIR)/$(MOZC_DICT_TXT); then \
			echo "⚠️  辞書の自動インポートに失敗しました。手動でインポートしてください。"; \
			echo "ファイルパス: $(MOZC_CONFIG_DIR)/$(MOZC_DICT_TXT)"; \
		fi; \
	else \
		echo "⚠️  mozc_toolが見つかりません。手動でインポートしてください。"; \
		echo "ファイルパス: $(MOZC_CONFIG_DIR)/$(MOZC_DICT_TXT)"; \
	fi

	@echo "✅ Mozc UT辞書のセットアップが完了しました。"

# Mozc辞書のインポート状況確認
check-mozc-import-status:
	@echo "🔍 Mozc辞書のインポート状況を確認中..."
	@if [ -f "$(MOZC_CONFIG_DIR)/$(MOZC_DICT_TXT)" ]; then \
		echo "✅ UT辞書ファイルが見つかりました: $(MOZC_CONFIG_DIR)/$(MOZC_DICT_TXT)"; \
		echo "📊 辞書ファイルの行数: $$(wc -l < $(MOZC_CONFIG_DIR)/$(MOZC_DICT_TXT))"; \
	else \
		echo "⚠️  UT辞書ファイルが見つかりません。setup-mozc-ut-dictionariesを実行してください。"; \
	fi

	@if command -v /usr/lib/mozc/mozc_tool >/dev/null 2>&1; then \
		echo "✅ mozc_toolが利用可能です"; \
	else \
		echo "⚠️  mozc_toolが見つかりません。Mozcが正しくインストールされていない可能性があります。"; \
	fi

	@echo "ℹ️  辞書の手動インポートが必要な場合は、以下のコマンドを実行してください:"; \
	echo "    /usr/lib/mozc/mozc_tool --mode=dictionary_tool"; \
	echo "    または Mozcの辞書ツールを使用してください。"

# Mozc UT辞書の手動セットアップ
setup-mozc-ut-dictionaries-manual:
	@echo "📚 Mozc UT辞書の手動セットアップを開始中..."
	@echo "ℹ️  以下の手順で辞書をインポートしてください:"
	@echo ""
	@echo "1. 辞書ファイルの確認:"
	@if [ -f "$(MOZC_CONFIG_DIR)/$(MOZC_DICT_TXT)" ]; then \
		echo "   ✅ 辞書ファイルが見つかりました: $(MOZC_CONFIG_DIR)/$(MOZC_DICT_TXT)"; \
	else \
		echo "   ⚠️  辞書ファイルが見つかりません。setup-mozc-ut-dictionariesを先に実行してください。"; \
		exit 1; \
	fi
	@echo ""
	@echo "2. 辞書ツールの起動:"
	@echo "   以下のコマンドを実行してMozc辞書ツールを起動してください:"
	@echo "   /usr/lib/mozc/mozc_tool --mode=dictionary_tool"
	@echo ""
	@echo "3. 辞書のインポート:"
	@echo "   - 辞書ツールで「管理」→「新規辞書にインポート」を選択"
	@echo "   - ファイルパス: $(MOZC_CONFIG_DIR)/$(MOZC_DICT_TXT)"
	@echo "   - 辞書名: 任意の名前（例: UT辞書）"
	@echo "   - フォーマット: Mozc"
	@echo ""
	@echo "4. 辞書の有効化:"
	@echo "   - インポートした辞書にチェックを入れて有効化"
	@echo "   - 「適用」ボタンをクリック"
	@echo ""
	@echo "✅ 手動セットアップの手順を表示しました。"

# Mozc UT辞書ファイルのチェックサム取得
get-mozc-dict-checksum:
	@echo "📋 Mozc UT辞書のチェックサムを取得中..."
	@echo "ℹ️  以下のコマンドを実行して実際のチェックサムを取得してください:"
	@echo ""
	@echo "1. 辞書ファイルをダウンロード:"
	@echo "   wget -O /tmp/$(MOZC_DICT_FILENAME) \"$(MOZC_DICT_URL)\""
	@echo ""
	@echo "2. チェックサムを取得:"
	@echo "   sha256sum /tmp/$(MOZC_DICT_FILENAME)"
	@echo ""
	@echo "3. 取得したチェックサムを mk/mozc.mk の MOZC_DICT_CHECKSUM 変数に設定"
	@echo ""
	@echo "⚠️  現在のチェックサム値はプレースホルダーです："
	@echo "   $(MOZC_DICT_CHECKSUM)"
	@echo ""
	@echo "✅ チェックサム取得方法を表示しました。"

# ========================================
# 新しい階層的な命名規則のターゲット
# ========================================

# Mozc関連設定系
setup-config-mozc: setup-mozc
setup-config-mozc-ut-dictionaries: setup-mozc-ut-dictionaries
setup-config-mozc-ut-dictionaries-manual: setup-mozc-ut-dictionaries-manual

# IME環境セットアップの統合
setup-config-ime: setup-mozc

# ========================================
# 後方互換性のためのエイリアス
# ========================================

# 古いターゲット名を維持（既に実装済み）
# setup-mozc-ut-dictionaries: は既に実装済み
# setup-mozc-ut-dictionaries-manual: は既に実装済み

# エクスポートコマンドの後方互換性
mozc-export-keymap: export-config-mozc-keymap
