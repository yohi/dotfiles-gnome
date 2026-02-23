# 短縮エイリアスのみを管理するファイル
# 廃止予定の旧名エイリアスは mk/deprecated-targets.mk で扱う

# ==================== 短縮エイリアス ====================
.PHONY: i s c u m h claudecode
i: install                ## 短縮: make install
s: setup                  ## 短縮: make setup
c: check-cursor-version   ## 短縮: Cursorバージョン確認
u: update-cursor          ## 短縮: Cursorアップデート
m: menu                   ## 短縮: インタラクティブメニュー
h: help                   ## 短縮: ヘルプ表示
claudecode: install-superclaude  ## 短縮: SuperClaudeフレームワークインストール

# 段階的セットアップの短縮形
.PHONY: s1 s2 s3 s4 s5 ss sg
s1: stage1    ## 短縮: ステージ1実行
s2: stage2    ## 短縮: ステージ2実行
s3: stage3    ## 短縮: ステージ3実行
s4: stage4    ## 短縮: ステージ4実行
s5: stage5    ## 短縮: ステージ5実行
ss: stage-status  ## 短縮: 進捗確認
sg: stage-guide   ## 短縮: セットアップガイド
