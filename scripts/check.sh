#!/usr/bin/env bash
#
# 必須チェックの単一入口
#
# このスクリプトは、プロジェクトの必須チェックを1箇所に集約する。
# hook、CI、手動実行のすべてがここを経由する。
#
# 終了コード
#   0  すべての必須チェックが成功した
#   1  いずれかの必須チェックが失敗した
#   2  必須チェックが未設定（成功ではない）
#
# 設定方法
#   1. docs/architecture.md §10 の表に必須チェックを定義する。
#   2. 下の「必須チェックの定義」へ run 行として記述する。
#   表とこのスクリプトの内容は一致させる。
#
# このスクリプトに技術固有のコマンドを直接書く。
# 基盤側は言語やフレームワークを固定しない。

set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

checks_total=0
checks_failed=0
failed_labels=()

# run <ラベル> <コマンド> [引数...]
run() {
  local label="$1"
  shift

  checks_total=$((checks_total + 1))

  printf '\n=== %s ===\n' "$label"
  printf '$ %s\n' "$*"

  "$@"
  local code=$?

  if [ "$code" -eq 0 ]; then
    printf -- '--- %s: 成功 ---\n' "$label"
  else
    printf -- '--- %s: 失敗 (exit %d) ---\n' "$label" "$code"
    checks_failed=$((checks_failed + 1))
    failed_labels+=("$label")
  fi
}

# ============================================================
# 必須チェックの定義
#
# 下の2件は技術スタックに依存しないため、既定で有効にしている。
# どのプロジェクトでも文書と設定ファイルは存在するため、
# コピー後もそのまま利用できる。
#
# 技術スタックを決めたら、ここへ run 行を追加する。
# 記述例（採用した技術に合わせて置き換える）:
#
#   run "静的解析"   npm run lint
#   run "型検査"     npm run typecheck
#   run "単体テスト" npm test
#   run "ビルド"     npm run build
#
# 存在しないコマンドを書かない。
# 実行できないチェックを定義済みとして扱わない。
# ============================================================

run "構文検査（シェル・JSON・YAML）" bash "$repo_root/scripts/lint-syntax.sh"
run "文書の参照切れ検査"             bash "$repo_root/scripts/lint-docs-references.sh"

# ============================================================
# ここまで
# ============================================================

if [ "$checks_total" -eq 0 ]; then
  cat >&2 <<'MSG'

必須チェックが未設定です。これは成功ではありません。

次の手順で設定してください。
  1. docs/architecture.md §10 の検証方法の表を埋める。
  2. scripts/check.sh の「必須チェックの定義」へ run 行を追加する。

設定するまで、このプロジェクトでは必須チェックの成功を報告できません。
MSG
  exit 2
fi

printf '\n============================================\n'
if [ "$checks_failed" -eq 0 ]; then
  printf '必須チェック: 成功（%d件）\n' "$checks_total"
  printf '============================================\n'
  exit 0
fi

printf '必須チェック: 失敗（%d件中 %d件）\n' "$checks_total" "$checks_failed"
for label in "${failed_labels[@]}"; do
  printf '  - %s\n' "$label"
done
printf '============================================\n'
exit 1
