# 作業記録

Issueごとの分析、計画、検証結果を置く。

## 1. 位置付け

このディレクトリは、工程間で成果物を受け渡すための場所である。

分析、計画、検証結果の**正本はこのディレクトリのファイル**とする。
Issueコメントへ要約を書く場合も、正本はここにある。

セッションをまたいでも前工程の成果物を参照できるようにするため、
Gitの管理対象に含める。

## 2. 配置

```
docs/work/
  <Issue番号>/
    analysis.md       Issue分析の結果
    plan.md           実装計画
    verification.md   検証結果
  templates/          各ファイルのひな形
```

ディレクトリ名はIssue番号のみとする（Issue #12 なら `12`）。
Issueに対応しない調査は作らない。調査もIssueとして管理する。

## 3. ファイルの役割

| ファイル | 作成する工程 | 作成するSkill |
|---|---|---|
| analysis.md | Issue分析 | issue-analysis |
| plan.md | 実装計画 | implementation-planning |
| verification.md | テスト・実装 | test-generation / implementation |

各ファイルへ何を書くかは、対応するSkillの「出力」を正本とする。
`templates/` のひな形は見出しの構成のみを示す。

## 4. 工程間の受け渡し

```
issue-analysis            → analysis.md を書く
implementation-planning   → analysis.md を読む     → plan.md を書く
implementation            → plan.md を読む         → verification.md を書く
test-generation           → plan.md を読む         → verification.md を追記する
code-review               → 上記すべてを読む
```

前工程の成果物が存在しない場合は、推測で補わない。
不足している工程を示し、必要な情報を求める。

## 5. 必要になった時点で作る

すべてのIssueに3ファイルを機械的に作らない。

小さな変更では、分析と計画を `plan.md` へまとめてよい。
記録をまとめることと、必要な判断や検証を省略することは区別する。

作らなかったファイルがある場合、その理由をIssueまたはPRへ記載する。

## 6. Issueとの対応

- 成果物の先頭に対象Issueへのリンクを書く
- Issueまたは PR から `docs/work/<番号>/` を辿れるようにする

どちらか一方向だけのリンクにしない。

## 7. 完了後

Issueが完了しても成果物は削除しない。

判断の経緯は、振り返りと将来の設計判断の参照元になる。
重要な設計判断は、必要に応じて `docs/adr/` へ切り出す。

## 8. 書かないもの

- 秘密、資格情報、本番の個人情報
- 外部へ共有できない情報
- 生成物やログの全文（必要な抜粋のみ）

このディレクトリはリポジトリへコミットされる。
