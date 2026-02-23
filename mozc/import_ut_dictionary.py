#!/usr/bin/env python3
"""
Mozc UT辞書自動インポートスクリプト
大量の辞書エントリを効率的にMozcのユーザー辞書データベースにインポートします。
"""

import sys
import os
import sqlite3
import time
import signal
import shutil
from pathlib import Path


def signal_handler(sig, frame):
    """シグナルハンドラー"""
    print('\n⚠️  処理が中断されました')
    sys.exit(1)


def setup_signal_handlers():
    """シグナルハンドラーの設定"""
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)


def optimize_database(conn):
    """データベースの最適化設定"""
    conn.execute('PRAGMA journal_mode = WAL')
    conn.execute('PRAGMA synchronous = NORMAL')
    conn.execute('PRAGMA cache_size = 50000')
    conn.execute('PRAGMA temp_store = MEMORY')
    conn.execute('PRAGMA mmap_size = 268435456')  # 256MB


def create_user_dictionary_table(conn):
    """ユーザー辞書テーブルの作成"""
    conn.execute('''
        CREATE TABLE IF NOT EXISTS user_dictionary (
            id INTEGER PRIMARY KEY,
            key TEXT,
            value TEXT,
            pos TEXT,
            comment TEXT
        )
    ''')

    # 既存のUT辞書エントリを削除
    conn.execute('DELETE FROM user_dictionary WHERE comment LIKE "UT辞書%"')
    conn.commit()


def import_dictionary_entries(conn, dictionary_file):
    """辞書エントリをインポート"""
    print(f'📖 辞書ファイルを読み込み中: {dictionary_file}')

    if not os.path.exists(dictionary_file):
        print(f'❌ 辞書ファイルが見つかりません: {dictionary_file}')
        return 0

    count = 0
    batch_data = []
    batch_size = 10000
    commit_interval = 50000

    try:
        with open(dictionary_file, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line or line.startswith('#'):
                    continue

                parts = line.split('\t')
                if len(parts) >= 4:
                    key, value, pos = parts[0], parts[1], parts[3]
                    if key and value:
                        batch_data.append((key, value, pos, 'UT辞書エントリ'))
                        count += 1

                        # バッチ処理
                        if len(batch_data) >= batch_size:
                            conn.executemany(
                                'INSERT INTO user_dictionary (key, value, pos, comment) VALUES (?, ?, ?, ?)',
                                batch_data
                            )
                            batch_data = []

                            # 定期的にコミット
                            if count % commit_interval == 0:
                                conn.commit()
                                print(f'📊 処理済み: {count:,} エントリ')

                # 進捗表示（読み込み中）
                if line_num % 100000 == 0:
                    print(f'📄 読み込み中: {line_num:,} 行')

        # 残りのデータを処理
        if batch_data:
            conn.executemany(
                'INSERT INTO user_dictionary (key, value, pos, comment) VALUES (?, ?, ?, ?)',
                batch_data
            )

        conn.commit()
        print(f'✅ {count:,} エントリがインポートされました')
        return count

    except (OSError, ValueError, sqlite3.Error) as e:
        print(f'❌ エラー: {e}')
        conn.rollback()
        return 0
    except Exception as e:
        import traceback
        print(f'❌ 予期せぬエラー: {e}')
        traceback.print_exc()
        conn.rollback()
        raise


def main():
    """メイン処理"""
    if len(sys.argv) != 3:
        print('使用法: python3 import_ut_dictionary.py <辞書ファイル> <データベースファイル>')
        sys.exit(1)

    dictionary_file = sys.argv[1]
    database_file = sys.argv[2]

    setup_signal_handlers()

    print('🤖 Mozc UT辞書自動インポート開始')
    print(f'📍 辞書ファイル: {dictionary_file}')
    print(f'📍 データベースファイル: {database_file}')

    # データベースディレクトリの作成
    db_dir = os.path.dirname(database_file)
    if db_dir:
        os.makedirs(db_dir, exist_ok=True)

    # 既存のデータベースをバックアップ
    if os.path.exists(database_file):
        backup_file = f'{database_file}.bak'
        try:
            shutil.copy2(database_file, backup_file)
            print(f'💾 既存データベースをバックアップ: {backup_file}')
        except OSError as e:
            print(f'⚠️  バックアップに失敗: {e}')

    try:
        print('🔧 データベースに接続中...')
        conn = sqlite3.connect(database_file, timeout=60)

        optimize_database(conn)
        create_user_dictionary_table(conn)

        start_time = time.time()
        imported_count = import_dictionary_entries(conn, dictionary_file)
        end_time = time.time()

        elapsed_time = end_time - start_time
        print(f'⏱️  処理時間: {elapsed_time:.2f}秒')

        if imported_count > 0:
            print('✅ 辞書の自動インポートが完了しました')
            print(f'📊 インポート済みエントリ数: {imported_count:,}')
        else:
            print('❌ 辞書のインポートに失敗しました')
            sys.exit(1)

    except Exception as e:
        print(f'❌ データベースエラー: {e}')
        sys.exit(1)
    finally:
        if 'conn' in locals():
            conn.close()


if __name__ == '__main__':
    main()
