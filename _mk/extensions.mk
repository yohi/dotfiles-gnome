# 拡張機能関連のターゲット
HOME_DIR ?= $(HOME)

# 拡張機能の依存関係をインストール
_install-extensions-dependencies:
	@echo "📦 拡張機能の依存関係をインストール中..."
	@sudo DEBIAN_FRONTEND=noninteractive apt-get update || true
	@sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
		gnome-shell-extension-manager \
		chrome-gnome-shell \
		gir1.2-gtop-2.0 \
		gir1.2-nm-1.0 \
		gir1.2-clutter-1.0 \
		python3-requests \
		python3-psutil \
		curl \
		jq || true

	@echo "✅ 拡張機能の依存関係のインストールが完了しました。"

# 拡張機能のインストール (v2)
install-extensions-v2:
	@echo "🔧 GNOME拡張機能をインストール中..."
	
	# 拡張機能リスト
	@EXTENSIONS="user-theme@gnome-shell-extensions.gcampax.github.com \
		dash-to-dock@micxgx.gmail.com \
		appindicatorsupport@rgcjonas.gmail.com \
		clipboard-indicator@tudmotu.com \
		gsconnect@andyholmes.github.io \
		openweather-extension@jenslody.de \
		system-monitor@paradoxxx.zero.gmail.com \
		workspace-indicator@gnome-shell-extensions.gcampax.github.com \
		vitals@corefunction.com \
		blur-my-shell@aunetx \
		caffeine@patapon.info \
		unite@hardpixel.eu"; \
	\
	for ext in $$EXTENSIONS; do \
		echo "📦 $$ext をインストール中..."; \
		if command -v gnome-extensions >/dev/null 2>&1; then \
			if gnome-extensions list | grep -q "$$ext"; then \
				echo "⏭️  $$ext は既にインストール済みです"; \
			else \
				echo "🔄 $$ext のインストールを試行中..."; \
				gdbus call --session --dest org.gnome.Shell.Extensions --object-path /org/gnome/Shell/Extensions --method org.gnome.Shell.Extensions.installRemoteExtension "$$ext" || echo "⚠️  $$ext のインストールに失敗しました"; \
			fi; \
		else \
			echo "⚠️  gnome-extensionsコマンドが見つかりません"; \
		fi; \
	done

	@echo "✅ GNOME拡張機能のインストールが完了しました。"

# 拡張機能の簡単インストール
install-extensions-simple:
	@echo "📦 基本的なGNOME拡張機能をインストール中..."
	
	# 基本的な拡張機能のリスト
	@BASIC_EXTENSIONS="user-theme@gnome-shell-extensions.gcampax.github.com \
		dash-to-dock@micxgx.gmail.com \
		appindicatorsupport@rgcjonas.gmail.com \
		clipboard-indicator@tudmotu.com"; \
	\
	for ext in $$BASIC_EXTENSIONS; do \
		echo "📦 $$ext をインストール中..."; \
		if command -v gnome-extensions >/dev/null 2>&1; then \
			if gnome-extensions list | grep -q "$$ext"; then \
				echo "⏭️  $$ext は既にインストール済みです"; \
			else \
				echo "🔄 $$ext のインストールを試行中..."; \
				gdbus call --session --dest org.gnome.Shell.Extensions --object-path /org/gnome/Shell/Extensions --method org.gnome.Shell.Extensions.installRemoteExtension "$$ext" || echo "⚠️  $$ext のインストールに失敗しました"; \
			fi; \
		else \
			echo "⚠️  gnome-extensionsコマンドが見つかりません"; \
		fi; \
	done

	@echo "✅ 基本的なGNOME拡張機能のインストールが完了しました。"

# 拡張機能のテスト
_test-extensions:
	@echo "🔍 GNOME拡張機能の状態を確認中..."
	
	@if command -v gnome-extensions >/dev/null 2>&1; then \
		echo "📋 インストール済み拡張機能:"; \
		gnome-extensions list; \
		echo ""; \
		echo "📋 有効な拡張機能:"; \
		gnome-extensions list --enabled; \
		echo ""; \
		echo "📋 無効な拡張機能:"; \
		gnome-extensions list --disabled; \
	else \
		echo "⚠️  gnome-extensionsコマンドが見つかりません"; \
	fi

	@echo "✅ 拡張機能の状態確認が完了しました。"

# 拡張機能の状態表示
_extensions-status:
	@echo "📊 GNOME拡張機能の詳細状態を表示中..."
	
	@if command -v gnome-extensions >/dev/null 2>&1; then \
		echo "=== インストール済み拡張機能 ==="; \
		gnome-extensions list --details; \
		echo ""; \
		echo "=== 有効な拡張機能 ==="; \
		gnome-extensions list --enabled --details; \
		echo ""; \
		echo "=== 無効な拡張機能 ==="; \
		gnome-extensions list --disabled --details; \
	else \
		echo "⚠️  gnome-extensionsコマンドが見つかりません"; \
	fi

	@echo "✅ 拡張機能の詳細状態表示が完了しました。"

# 拡張機能スキーマの修正
fix-extensions-schema:
	@echo "🔧 拡張機能スキーマを修正中..."
	
	# スキーマのコンパイル
	@echo "📦 GSettingsスキーマをコンパイル中..."
	@if [ -d "/usr/share/glib-2.0/schemas" ]; then \
		sudo glib-compile-schemas /usr/share/glib-2.0/schemas/ || true; \
		echo "✅ システムスキーマがコンパイルされました"; \
	fi
	
	@if [ -d "$(HOME_DIR)/.local/share/glib-2.0/schemas" ]; then \
		glib-compile-schemas $(HOME_DIR)/.local/share/glib-2.0/schemas/ || true; \
		echo "✅ ユーザースキーマがコンパイルされました"; \
	fi

	# 拡張機能の再読み込み
	@echo "🔄 拡張機能を再読み込み中..."
	@if command -v gnome-extensions >/dev/null 2>&1; then \
		gnome-extensions list --enabled | while read -r ext; do \
			echo "🔄 $$ext を再読み込み中..."; \
			gnome-extensions disable "$$ext" || true; \
			sleep 1; \
			gnome-extensions enable "$$ext" || true; \
		done; \
	fi

	@echo "✅ 拡張機能スキーマの修正が完了しました。"
	@echo "ℹ️  変更を反映するため、ログアウト・ログインまたはAlt+F2でrを実行してください。"
