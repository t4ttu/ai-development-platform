#!/usr/bin/env bash
#
# シェル、JSON、YAML の構文を確認する。
#
# 目的
#   壊れた設定ファイルやスクリプトがリポジトリへ入るのを防ぐ。
#   hook と CI の設定は壊れていても気付きにくいため、機械的に確認する。
#
# 終了コード
#   0  すべての対象が構文上妥当で、必要な検査を実施できた
#   1  構文エラーがある、または必要な検査ツールが無く検証できなかった
#
# shellcheck は参考扱いとする。
# 未導入の環境では未実施として報告し、失敗にはしない。

set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

errors=0
skipped=()

section() { printf '\n[%s]\n' "$1"; }

# ---------- シェルスクリプト ----------
section "シェル構文 (bash -n)"

shell_files=()
while IFS= read -r f; do
  shell_files+=("$f")
done < <(find scripts .claude/hooks -type f -name '*.sh' 2>/dev/null | sort)

if [ "${#shell_files[@]}" -eq 0 ]; then
  echo "対象のシェルスクリプトがありません。検査条件を確認してください。"
  errors=$((errors + 1))
else
  for f in "${shell_files[@]}"; do
    if bash -n "$f" 2>/tmp/lint-shell-err; then
      printf '  OK   %s\n' "$f"
    else
      printf '  NG   %s\n' "$f"
      sed 's/^/       /' /tmp/lint-shell-err
      errors=$((errors + 1))
    fi
  done
fi

# ---------- shellcheck（参考） ----------
section "shellcheck（参考）"

if command -v shellcheck >/dev/null 2>&1; then
  for f in "${shell_files[@]}"; do
    if shellcheck -S warning "$f"; then
      printf '  OK   %s\n' "$f"
    else
      printf '  指摘あり %s（参考扱い。失敗にはしません）\n' "$f"
    fi
  done
else
  echo "  未実施: shellcheck が未導入です。構文検査(bash -n)のみ実施しました。"
  skipped+=("shellcheck")
fi

# ---------- JSON ----------
section "JSON構文"

json_files=()
while IFS= read -r f; do
  json_files+=("$f")
done < <(git ls-files '*.json' 2>/dev/null | sort)

if [ "${#json_files[@]}" -eq 0 ]; then
  echo "  対象なし"
elif ! command -v python3 >/dev/null 2>&1; then
  echo "  未実施: python3 が無いためJSONを検証できません。未検証を成功として扱わないため失敗とします。"
  errors=$((errors + 1))
else
  for f in "${json_files[@]}"; do
    if python3 -c "import json,sys; json.load(open(sys.argv[1], encoding='utf-8'))" "$f" 2>/tmp/lint-json-err; then
      printf '  OK   %s\n' "$f"
    else
      printf '  NG   %s\n' "$f"
      sed 's/^/       /' /tmp/lint-json-err
      errors=$((errors + 1))
    fi
  done
fi

# ---------- YAML ----------
section "YAML構文"

yaml_files=()
while IFS= read -r f; do
  yaml_files+=("$f")
done < <(git ls-files '*.yml' '*.yaml' 2>/dev/null | sort)

yaml_cmd=""
if python3 -c "import yaml" >/dev/null 2>&1; then
  yaml_cmd="python3"
elif command -v ruby >/dev/null 2>&1; then
  yaml_cmd="ruby"
fi

if [ "${#yaml_files[@]}" -eq 0 ]; then
  echo "  対象なし"
elif [ -z "$yaml_cmd" ]; then
  echo "  未実施: YAMLを解析できるツール（python3のyaml、またはruby）がありません。未検証を成功として扱わないため失敗とします。"
  errors=$((errors + 1))
else
  printf '  使用: %s\n' "$yaml_cmd"
  for f in "${yaml_files[@]}"; do
    case "$yaml_cmd" in
      python3) ok_cmd=(python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1], encoding='utf-8'))" "$f") ;;
      ruby)    ok_cmd=(ruby -ryaml -e 'YAML.load_file(ARGV[0])' "$f") ;;
    esac
    if "${ok_cmd[@]}" 2>/tmp/lint-yaml-err; then
      printf '  OK   %s\n' "$f"
    else
      printf '  NG   %s\n' "$f"
      sed 's/^/       /' /tmp/lint-yaml-err
      errors=$((errors + 1))
    fi
  done
fi

# ---------- 結果 ----------
printf '\n'
if [ "${#skipped[@]}" -gt 0 ]; then
  printf '未実施: %s\n' "${skipped[*]}"
fi

if [ "$errors" -gt 0 ]; then
  printf '構文検査: 失敗（%d件）\n' "$errors"
  exit 1
fi

printf '構文検査: 成功\n'
exit 0
