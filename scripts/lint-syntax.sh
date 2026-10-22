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
 空配列の扱い
# macOS の bash は 3.2 で、set -u のもとでは空配列の展開
# "${arr[@]}" と "${arr[*]}" が未定義変数エラーになる。
# 要素数の参照 ${#arr[@]} は安全。
# 配列を展開する前に要素数で分岐する。
#
# ShellCheck は参考扱いとする。
# 未導入の環境では未実施として報告し、失敗にはしない。
#
# 行頭を "# shellcheck " で始めると shellcheck のディレクティブとして
# 解析され、そのファイルの検査が一部スキップされる（SC1073）。
# コメントでは先頭を避けて表記する。

set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

errors=0
skipped=()

section() { printf '\n[%s]\n' "$1"; }

# ファイル列挙の方法を決める。
#   gitの管理下では git ls-files を使い、.gitignore を尊重する。
#   git管理外（コピー直後で git init していない場合など）は find で列挙する。
#
# git ls-files は git管理外では失敗するが、パイプラインの終了コードには
# 現れない。そのまま使うと対象0件となり、検査が「対象なし」として
# 通過してしまう。未検証を成功として扱わないため、列挙方法を明示する。
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  file_source="git ls-files"
else
  file_source="find"
fi

# list_files <拡張子>...
list_files() {
  local ext
  for ext in "$@"; do
    if [ "$file_source" = "git ls-files" ]; then
      git ls-files "*.$ext"
    else
      find . -type f -name "*.$ext" \
        -not -path './.git/*' \
        -not -path './node_modules/*' \
        -not -path './vendor/*' \
        -not -path './dist/*' \
        -not -path './build/*' \
        -not -path './.venv/*' \
        -not -path './target/*' \
        | sed 's|^\./||'
    fi
  done
}

printf 'ファイル列挙: %s\n' "$file_source"

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

if [ "${#shell_files[@]}" -eq 0 ]; then
  echo "  対象なし"
elif command -v shellcheck >/dev/null 2>&1; then
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
done < <(list_files json 2>/dev/null | sort -u)

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
done < <(list_files yml yaml 2>/dev/null | sort -u)

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

# ---------- SKILL.md の frontmatter ----------
section "SKILL.md の frontmatter"

skill_files=()
while IFS= read -r f; do
  skill_files+=("$f")
done < <(find .claude/skills -type f -name 'SKILL.md' 2>/dev/null | sort)

if [ "${#skill_files[@]}" -eq 0 ]; then
  echo "  対象なし"
elif [ -z "$yaml_cmd" ]; then
  echo "  未実施: YAMLを解析できるツールがありません。未検証を成功として扱わないため失敗とします。"
  errors=$((errors + 1))
else
  for f in "${skill_files[@]}"; do
    case "$yaml_cmd" in
      python3) fm_cmd=(python3 -c "import re,sys,yaml
src=open(sys.argv[1],encoding='utf-8').read()
m=re.match(r'\A---\n(.*?)\n---\n', src, re.S)
if not m: raise SystemExit('frontmatter が見つかりません')
d=yaml.safe_load(m.group(1))
if not isinstance(d, dict): raise SystemExit('frontmatter がマップではありません')
for k in ('name','description'):
    if not d.get(k): raise SystemExit(f'{k} がありません')
for k in ('disallowed-tools','allowed-tools'):
    v=d.get(k)
    if v is not None and not isinstance(v,(list,str)): raise SystemExit(f'{k} はリストか文字列である必要があります')
" "$f") ;;
      ruby)    fm_cmd=(ruby -ryaml -e '
src = File.read(ARGV[0])
fm = src[/\A---\n(.*?)\n---\n/m, 1]
abort "frontmatter が見つかりません" if fm.nil?
begin
  d = YAML.safe_load(fm)
rescue Psych::SyntaxError => e
  abort "frontmatter のYAMLが不正です: #{e.message}"
end
abort "frontmatter がマップではありません" unless d.is_a?(Hash)
%w[name description].each { |k| abort "#{k} がありません" if d[k].to_s.empty? }
%w[disallowed-tools allowed-tools].each do |k|
  v = d[k]
  abort "#{k} はリストか文字列である必要があります" unless v.nil? || v.is_a?(Array) || v.is_a?(String)
end
' "$f") ;;
    esac
    if "${fm_cmd[@]}" 2>/tmp/lint-fm-err; then
      printf '  OK   %s\n' "$f"
    else
      printf '  NG   %s\n' "$f"
      sed 's/^/       /' /tmp/lint-fm-err
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
