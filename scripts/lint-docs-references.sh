#!/usr/bin/env bash
#
# 文書内で参照しているプロジェクト内パスが実在するかを確認する。
#
# 目的
#   「記載どおりに作業できない文書」を検出する。
#   存在しないディレクトリやファイルへの参照を残さない。
#
# 対象
#   リポジトリ内の *.md に現れる docs/ scripts/ .claude/ .github/ 配下のパス。
#   `*` を含むパスはグロブ例とみなして対象外とする。
#
# 文書内で例示を書くときの規約
#   実在しないパスを例として示す場合は、可変部分を <...> で書く。
#   例: docs/work/<Issue番号>/ は docs/work/ までを参照として扱う。
#   実在する具体パスをそのまま書くと、参照切れとして検出される。
#
# 終了コード
#   0  参照切れなし
#   1  参照切れあり

set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

# 存在しないことを承知している参照。
# 追跡Issueを必ず併記し、解消したらこの一覧から削除する。
# 新規プロジェクトへコピーしたときは、この一覧を空にする。
# ここに挙がっているIssue番号はこの基盤リポジトリのものである。
allowed_missing=(
  "docs/adr/"             # #10 ADRテンプレートを追加予定
  ".claude/rules/local/"  # #10 記述を見直し予定
)

is_allowed_missing() {
  local target="$1"
  local allowed
  for allowed in "${allowed_missing[@]}"; do
    [ "$target" = "$allowed" ] && return 0
  done
  return 1
}

missing_count=0
resolved_count=0

# 文書に現れるプロジェクト内パスを収集する。
#
# 抽出前に次を除去する。
#
# 1. コードフェンス（``` で囲まれた範囲）
#    コマンド例、ツールの出力、ディレクトリ構成の例示が入る。
#    これらは「文書が辿るべき参照」ではないため対象外とする。
#    検証記録がツールの出力を引用できるようにするための除去でもある。
# 2. 外部URL
#    スキーム付き（https://...）と、スキームの無いホスト名表記の両方。
#    例: code.claude.com/docs/en/skills を docs/en/skills と誤認しない。
referenced_paths="$(
  grep -rh --include="*.md" -e '' . 2>/dev/null \
    | awk '/^[[:space:]]*```/ { infence = !infence; next } !infence' \
    | sed -E 's#https?://[^[:space:])"'"'"']*##g' \
    | sed -E 's#[A-Za-z0-9][A-Za-z0-9.-]*\.(com|org|net|io|dev|ai|jp|co|me)/[^[:space:])"'"'"']*##g' \
    | grep -oE '(\./)?(docs|scripts|\.claude|\.github)/[A-Za-z0-9_./*-]+' \
    | sed 's|^\./||' \
    | sed 's/[。、.]*$//' \
    | sort -u
)"

if [ -z "$referenced_paths" ]; then
  echo "参照対象のパスが見つかりませんでした。検査条件を確認してください。"
  exit 1
fi

while IFS= read -r path; do
  [ -z "$path" ] && continue

  # グロブ例は参照ではないため対象外
  case "$path" in
    *'*'*) continue ;;
  esac

  if [ -e "$path" ]; then
    # 例外リストに残っているが実在するようになった場合は知らせる
    if is_allowed_missing "$path"; then
      printf '例外リストから削除できます: %s（実在するようになりました）\n' "$path"
      resolved_count=$((resolved_count + 1))
    fi
    continue
  fi

  if is_allowed_missing "$path"; then
    printf '既知の未作成（追跡中）: %s\n' "$path"
    continue
  fi

  printf '参照切れ: %s\n' "$path"
  missing_count=$((missing_count + 1))
done <<< "$referenced_paths"

if [ "$missing_count" -gt 0 ]; then
  printf '\n参照切れが %d 件あります。参照先を作成するか、文書の記載を修正してください。\n' "$missing_count"
  printf '意図的に未作成とする場合は、scripts/lint-docs-references.sh の allowed_missing へ追跡Issue付きで追加してください。\n'
  exit 1
fi

if [ "$resolved_count" -gt 0 ]; then
  printf '\n参照切れはありません（例外リストの整理候補が %d 件）。\n' "$resolved_count"
else
  printf '\n参照切れはありません。\n'
fi
exit 0
