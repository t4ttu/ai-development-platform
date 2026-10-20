# 実装計画: #2 工程間の成果物の置き場を確定し、Skillを連鎖させる

- 対象Issue: #2
- 分析: Issue #2 本文に記載済み（docs/work/README.md §5 に従い analysis.md は作成していない）
- 作成日: 2026-10-20

## 目的と範囲

分析、計画、検証結果の正本を1箇所に確定し、
5つのSkillが前工程の成果物を参照できる状態にする。

対象外:

- 既存プロジェクトの過去成果物の移行
- 成果物の自動生成や自動同期の仕組み

## 解消した未決事項

Issue本文の「依存関係・未決事項」3件について判断を得た。

| 未決事項 | 決定 | 理由 |
|---|---|---|
| 正本の場所 | `docs/work/<Issue番号>/` | README §6 の「GitHub未使用でも開発を開始できる」方針と整合する。AIがファイル読み取りだけで前工程を参照できる |
| Git管理 | 含める | セッションをまたいで残り、他者とCIからも参照できる。含めない場合 #2 の目的（工程間の連鎖）を満たさない |
| 完了後の扱い | そのまま残す | 振り返り（#8 retrospective）の入力になり、判断の経緯がADRの種になる |

Issueコメントへ書く場合は要約とし、正本へのリンクを添える方式とした。
`development-workflow.md` §8 の「同じ情報を複数箇所で正本として管理しない」を満たす。

## 実装方針

### 採用した方式

1. `docs/work/<Issue番号>/` に `analysis.md` / `plan.md` / `verification.md` を置く
2. ファイルの内容の正本は各SKILL.mdの「出力」とし、`templates/` は見出しの骨組みのみを持つ
3. 各SKILL.mdへ「前工程の成果物を読む」「自分の成果物を所定の場所へ書く」を追加する

### 2 の理由

テンプレートとSKILL.mdの両方に記載内容を書くと二重管理になる（#6 の指摘と同じ構造）。
テンプレートの冒頭に「記載内容は該当SKILL.mdの出力を正本とする」と明記し、
骨組みと内容定義の責務を分けた。

### 検討した代替案

- **Issueコメントを正本にする**: `development-workflow.md` §2 の「Issueを開発管理の中心にする」方針には整合するが、GitHub接続が必須になり、CIやローカルから参照しづらい。README §6 がGitHub未使用での開始を認めているため不採用
- **両方に正本を置く**: 可読性は高いが §8 の「同じ情報を複数箇所で正本として管理しない」に反する。更新漏れのリスクがあるため不採用

## 変更対象

| ファイル | 変更 |
|---|---|
| `docs/work/README.md` | 新規。位置付け、配置、役割、受け渡し、Issueとの対応、完了後の扱い |
| `docs/work/templates/analysis.md` | 新規。issue-analysis の出力に対応 |
| `docs/work/templates/plan.md` | 新規。implementation-planning の出力に対応 |
| `docs/work/templates/verification.md` | 新規。implementation / test-generation の出力に対応 |
| `.claude/skills/issue-analysis/SKILL.md` | 参照・手順10・出力・完了条件 |
| `.claude/skills/implementation-planning/SKILL.md` | 参照・手順1・出力・完了条件 |
| `.claude/skills/implementation/SKILL.md` | 参照・手順2・手順11・出力・完了条件 |
| `.claude/skills/test-generation/SKILL.md` | 参照・手順1・手順10・出力・完了条件 |
| `.claude/skills/code-review/SKILL.md` | 参照・手順2 |
| `docs/standards/development-workflow.md` | §8 の二択を解消。4.3/4.4/4.6 のアウトプットを具体化 |
| `docs/standards/issue-management.md` | §10 に作業記録との関連付けを追加 |
| `README.md` | §2 のディレクトリ表に `docs/work/` を追加 |
| `scripts/lint-docs-references.sh` | `allowed_missing` から `docs/work/` を削除。例示の書き方の規約を追記 |

## 受入条件と検証

| 受入条件 | 検証方法 | 期待結果 |
|---|---|---|
| §8 に正本が1つだけ記載されている | 文書の確認 | 二択の記述が無い |
| `docs/work/` が存在し構成と役割が説明されている | 文書の確認 | README.md に配置と役割の表がある |
| issue-analysis を実行すると所定の場所に書き出される | 実際にSkillを実行する | `docs/work/<番号>/analysis.md` が生成される |
| 新セッションで分析結果が貼り直し不要で参照される | 新セッションでの実行 | 別セッションでの確認が必要 |
| 各SKILL.mdに前工程の成果物のパスが記載されている | grep | 5ファイルすべてに記載がある |
| Issueから成果物、成果物からIssueへ辿れる | 文書とIssueの確認 | 双方向のリンクがある |

## 作業順序

1. `docs/work/README.md` とテンプレート3件を作成
2. `lint-docs-references.sh` の例外リストを更新
3. 5つのSKILL.mdを更新
4. 開発標準3件（workflow、issue-management、README）を更新
5. Skillを実行して成果物の生成を確認
6. 必須チェックを実行

## 移行・運用

- 既存プロジェクトへは自動反映されない（#9 と関連）
- コピー後は `docs/work/` 配下のIssue別ディレクトリを削除する。テンプレートは残す
- `docs/work/` がPRの差分に含まれるため、レビュー時はコードの変更と作業記録を区別する

## 判断待ち

### #4 への制約

`code-review` と `issue-analysis` に `disallowed-tools` を設定する場合、
`issue-analysis` は `docs/work/` への書き込みが必要になる。

全面的な書き込み禁止にはできない。`Edit(docs/work/**)` を許可する形にするか、
`issue-analysis` は読み取り専用の対象外とするかを #4 で判断する。

この制約を #4 へ記録する必要がある。
