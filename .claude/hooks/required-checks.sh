#!/usr/bin/env bash
#
# Stop hook: 応答を返し終える直前に必須チェックを実行し、結果を報告する。
#
# 目的
#   「テストを実行せずに完了と報告する」ことを構造的に防ぐ。
#   未検証および失敗を、成功として通過させない。
#
# scripts/check.sh の終了コードごとの扱い
#   0  成功        → 成功した事実を文脈へ渡す（ブロックしない）
#   2  未設定      → 未設定として報告する（成功扱いにしない。ブロックしない）
#   1  失敗        → 同一の失敗につき1回だけブロックする（exit 2）
#   他 実行エラー  → 実行できなかった事実を報告する（ブロックしない）
#
# 無限ループ対策
#   - stop_hook_active が true のときは何もしない。
#   - 同じ失敗内容で繰り返しブロックしない（失敗内容の署名を記録して比較する）。
#
# 外部依存
#   bash と coreutils のみ。jq などは使用しない。

set -uo pipefail

stdin_payload="$(cat 2>/dev/null || true)"

project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
check_script="$project_dir/scripts/check.sh"
state_dir="$project_dir/.claude/.cache"
guard_file="$state_dir/last-blocked-check"

emit_context() {
  # $1: Claudeへ渡す文脈（JSON文字列として安全な固定文のみを渡す）
  printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}\n' "$1"
}

# このhookによる継続中は、再度ブロックしない
if printf '%s' "$stdin_payload" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

if [ ! -f "$check_script" ]; then
  emit_context "必須チェック: scripts/check.sh が存在しないため実行されていません。検証は未実施です。成功として報告しないでください。"
  exit 0
fi

if [ ! -x "$check_script" ]; then
  emit_context "必須チェック: scripts/check.sh に実行権限がないため実行されていません。検証は未実施です。成功として報告しないでください。"
  exit 0
fi

check_output="$("$check_script" 2>&1)"
check_status=$?

mkdir -p "$state_dir" 2>/dev/null || true

case "$check_status" in
  0)
    rm -f "$guard_file" 2>/dev/null || true
    emit_context "必須チェック: 成功（scripts/check.sh, exit 0）。"
    exit 0
    ;;
  2)
    rm -f "$guard_file" 2>/dev/null || true
    emit_context "必須チェック: 未設定（scripts/check.sh, exit 2）。これは成功ではありません。必須チェックが成功したとは報告できません。未検証範囲として扱ってください。"
    exit 0
    ;;
esac

# exit 1 またはその他 = 失敗
signature="$(printf '%s' "$check_output" | cksum | tr -s ' ' '-')"
previous=""
[ -f "$guard_file" ] && previous="$(cat "$guard_file" 2>/dev/null || true)"

if [ "$signature" = "$previous" ]; then
  # 同一の失敗で既にブロック済み。ループを避けるため報告のみ行う。
  emit_context "必須チェック: 同一の失敗が解消していません（scripts/check.sh, exit ${check_status}）。成功として報告しないでください。未解決の失敗として報告してください。"
  exit 0
fi

printf '%s\n' "$signature" > "$guard_file" 2>/dev/null || true

{
  printf '必須チェックが失敗しました（scripts/check.sh, exit %s）。\n' "$check_status"
  printf '原因を調査して修正してください。未検証のまま完了と報告しないでください。\n'
  printf '修正できない場合は、失敗した事実と未検証範囲を明示して報告してください。\n'
  printf '\n--- scripts/check.sh の出力 ---\n'
  printf '%s\n' "$check_output"
} >&2

exit 2
