#!/usr/bin/env bash
#
# Issueテンプレートの Ready 確認欄が、
# docs/standards/issue-management.md §5 の条件と一致しているかを確認する。
#
# 目的
#   Ready の条件は §5 を正本とし、テンプレートはその写しである。
#   片方だけが更新されると、実装着手のゲートが正本と食い違う。
#   この乖離を機械的に検出する。
#
# 対象
#   .github/ISSUE_TEMPLATE/usecase.yml
#   .github/ISSUE_TEMPLATE/task.yml
#   （bug.yml は Ready 確認欄を持たない）
#
# 終了コード
#   0  一致している
#   1  不一致、または検査ツールが無く検証できなかった

set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

spec_file="docs/standards/issue-management.md"
targets=(
  ".github/ISSUE_TEMPLATE/usecase.yml"
  ".github/ISSUE_TEMPLATE/task.yml"
)

if [ ! -f "$spec_file" ]; then
  printf '%s が見つかりません。\n' "$spec_file" >&2
  exit 1
fi

for f in "${targets[@]}"; do
  if [ ! -f "$f" ]; then
    printf '%s が見つかりません。\n' "$f" >&2
    exit 1
  fi
done

if python3 -c "import yaml" >/dev/null 2>&1; then
  engine="python3"
elif command -v ruby >/dev/null 2>&1; then
  engine="ruby"
else
  echo "未実施: YAMLを解析できるツール（python3のyaml、またはruby）がありません。" >&2
  echo "未検証を成功として扱わないため失敗とします。" >&2
  exit 1
fi

printf '正本: %s §5\n' "$spec_file"
printf '使用: %s\n\n' "$engine"

if [ "$engine" = "python3" ]; then
  python3 - "$spec_file" "${targets[@]}" <<'PY'
import re, sys, yaml

spec_path, *targets = sys.argv[1:]
text = open(spec_path, encoding='utf-8').read()
m = re.search(r'## 5\. Readyの条件\n(.*?)\n\n内部実装', text, re.S)
if not m:
    print("§5 のReady条件を抽出できませんでした。見出しの構成を確認してください。", file=sys.stderr)
    sys.exit(1)
spec = re.findall(r'- \[ \] (.+)', m.group(1))
if not spec:
    print("§5 にチェックリスト項目がありません。", file=sys.stderr)
    sys.exit(1)

failed = False
for t in targets:
    d = yaml.safe_load(open(t, encoding='utf-8'))
    block = next((b for b in (d.get('body') or []) if b.get('id') == 'ready'), None)
    if block is None:
        print(f"  NG   {t}: id: ready のチェックリストがありません")
        failed = True
        continue
    got = [o.get('label') for o in block['attributes'].get('options', [])]
    if got == spec:
        print(f"  OK   {t}（{len(got)}項目）")
        continue
    failed = True
    print(f"  NG   {t}: §5 と一致しません")
    for item in spec:
        if item not in got:
            print(f"         テンプレートに無い: {item}")
    for item in got:
        if item not in spec:
            print(f"         §5 に無い:           {item}")
    if sorted(got) == sorted(spec):
        print("         項目の順序が異なります")

sys.exit(1 if failed else 0)
PY
else
  ruby - "$spec_file" "${targets[@]}" <<'RB'
require 'yaml'

spec_path, *targets = ARGV
text = File.read(spec_path)
m = text[/## 5\. Readyの条件\n(.*?)\n\n内部実装/m, 1]
if m.nil?
  warn "§5 のReady条件を抽出できませんでした。見出しの構成を確認してください。"
  exit 1
end
spec = m.scan(/- \[ \] (.+)/).flatten
if spec.empty?
  warn "§5 にチェックリスト項目がありません。"
  exit 1
end

failed = false
targets.each do |t|
  d = YAML.load_file(t)
  block = (d['body'] || []).find { |b| b['id'] == 'ready' }
  if block.nil?
    puts "  NG   #{t}: id: ready のチェックリストがありません"
    failed = true
    next
  end
  got = (block['attributes']['options'] || []).map { |o| o['label'] }
  if got == spec
    puts "  OK   #{t}（#{got.size}項目）"
    next
  end
  failed = true
  puts "  NG   #{t}: §5 と一致しません"
  (spec - got).each { |i| puts "         テンプレートに無い: #{i}" }
  (got - spec).each { |i| puts "         §5 に無い:           #{i}" }
  puts "         項目の順序が異なります" if got.sort == spec.sort
end

exit(failed ? 1 : 0)
RB
fi

status=$?
printf '\n'
if [ "$status" -eq 0 ]; then
  echo "Ready確認欄: 正本と一致"
else
  echo "Ready確認欄: 正本と不一致。issue-management.md §5 とテンプレートを揃えてください。"
fi
exit "$status"
