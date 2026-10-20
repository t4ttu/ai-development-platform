# 実装計画: #4 Skillの操作制約をfrontmatterで強制する

- 対象Issue: #4
- 分析: Issue #4 本文に記載済み
- 作成日: 2026-10-21

## 目的と範囲

Skillの操作制約を、本文の依頼文からクライアント側の強制へ移す。

現状、`code-review` は「コード変更、外部投稿、マージを行わない」と
本文に書いているだけで、`issue-analysis` も同様である。

## 調査で判明した仕様

実装方針を左右する事実を確認した。

| 項目 | 結果 |
|---|---|
| `disallowed-tools` | Skillが有効な間、ツールをClaudeの利用可能プールから**実際に取り除く**。次のメッセージで解除される |
| `allowed-tools` | 事前承認であり**制限にはならない**。列挙しないツールも呼び出せる |
| パス単位の指定（`Edit(docs/**)`） | 公式文書に記載が無い。確認できるのはコマンドパターン（`Bash(...)`）のみ |
| `$ARGUMENTS` | 現状のままで正しい。変更不要 |

`allowed-tools` は制限として使えないため、遮断は `disallowed-tools` で行う。

パス単位の指定が使えないため、`docs/work/` のみ書き込みを許すという
精密な制御はできない。これが設計上の制約になる。

## 解消した未決事項

| 未決事項 | 決定 | 理由 |
|---|---|---|
| `issue-analysis` の制約方針 | 外部書き込み系のみ遮断 | `docs/work/<Issue番号>/analysis.md` の書き出しに Edit / Write が必要。パス単位の指定が使えないため、ファイル変更の一括遮断はできない |
| `implementation` / `test-generation` の遮断範囲 | 外部操作のみ | 実装、テスト、コミットは工程に必要。push以降を遮断すれば「Skill呼び出しをpush・マージ・デプロイの許可と解釈しない」を強制できる |

### 選択肢の指定からの調整

`issue-analysis` の遮断対象として `Bash(gh pr *)` が候補に挙がっていたが、
`gh pr view` や `gh pr diff` まで遮断され、分析時の調査を妨げる。

「外部書き込み系のみ遮断」という意図に合わせ、
書き込み系サブコマンドのみを列挙する方式へ調整した。

## 実装方針

### Skillごとの遮断範囲

| Skill | 遮断 | 件数 |
|---|---|---|
| issue-analysis | 外部書き込み（push / PR書き込み / Issue書き込み） | 15 |
| implementation-planning | 同上 | 15 |
| implementation | 外部操作（push / PR作成・マージ / リリース） | 9 |
| test-generation | 同上 | 9 |
| code-review | 上記＋ファイル変更（Edit / Write / NotebookEdit）＋コミット | 19 |

`implementation-planning` はIssue本文の対象範囲に明記が無いが、
`issue-analysis` と同じ性質（読み取りと自分の成果物の書き出しのみ）のため
同じ扱いとした。

### 強制と指示の区別を本文へ明記する

パス単位の指定が使えないため、
`issue-analysis` と `implementation-planning` の
「コードを変更しない」はツールレベルで強制できない。

各SKILL.mdへ、強制されている範囲と指示にとどまる範囲を表で明記する。
強制されていないものを強制されていると誤認させない。

## 変更対象

| ファイル | 変更 |
|---|---|
| `.claude/skills/*/SKILL.md`（5件） | frontmatterへ `argument-hint` と `disallowed-tools` を追加。操作範囲の節へ強制範囲の説明を追加 |
| `scripts/lint-syntax.sh` | SKILL.md の frontmatter 検査を追加 |
| `README.md` §5 | Skillごとに遮断される操作の表と、照合の限界 |

### 範囲の追加について

`lint-syntax.sh` への frontmatter 検査はIssue本文の対象範囲に無い。

追加した理由は、frontmatterのYAMLが壊れると
**遮断設定が静かに失われる**ためである。
#4 が設置する制約そのものを守るための検査である。

検査内容は、frontmatterの存在、YAMLとして妥当か、
`name` と `description` の存在、
`disallowed-tools` / `allowed-tools` がリストか文字列か。

## 受入条件と検証

| 受入条件 | 検証方法 | 期待結果 |
|---|---|---|
| `code-review` 実行中に Edit / Write が拒否される | 別セッションでSkillを実行し編集を試みる | 拒否される |
| `issue-analysis` 実行中に Edit / Write が拒否される | — | **この受入条件は満たさない**。下記参照 |
| `/` メニューに引数のヒントが表示される | 目視 | 表示される |
| frontmatterの設定と本文の記述が一致している | 文書の確認 | 一致している |
| 遮断後も本来の出力を生成できる | Skillの実行 | レビュー結果、分析結果が得られる |

### 満たさない受入条件

Issue本文の受入条件「`issue-analysis` を実行中に Edit / Write が拒否される」は、
**意図的に満たさない**。

`docs/work/` への書き出しに必要であり、パス単位の指定が使えないため、
拒否すると #2 で定めた工程間の受け渡しが壊れる。

代わりに外部書き込み系を遮断した。
受入条件の更新が必要である。

### 検証上の制約

frontmatterはセッション開始時およびSkill呼び出し時に読まれる。
本セッションで作成した設定が実際に遮断するかは、
別セッションでの確認が必要になる。

## 作業順序

1. `disallowed-tools` と `allowed-tools` の仕様を確認（完了）
2. 5つのSKILL.mdのfrontmatterを更新
3. 各SKILL.mdの操作範囲へ強制範囲の説明を追加
4. `lint-syntax.sh` へ frontmatter 検査を追加
5. `README.md` §5 を更新
6. 必須チェックを実行
7. 別セッションで遮断の実動作を確認

## 移行・運用

- 遮断はコマンド文字列への照合であり、`git -C . push` のような別形式は対象外。#1 の deny ルールと同じ限界を持つ
- Skillの外では遮断されない。次のメッセージで解除される
- `code-review` で検出した問題の修正は、Skillの外で別途依頼する運用になる

## 判断待ち

### Issue #4 の受入条件の更新

「`issue-analysis` 実行中に Edit / Write が拒否される」を
「`issue-analysis` 実行中に外部書き込み操作が拒否される」へ変更する必要がある。

### パス単位の指定の検証

`disallowed-tools: Edit(docs/**)` のようなパス単位の指定が
実際に機能するかは未確認。機能するなら、
`docs/work/` 以外への書き込みを遮断する精密な制御が可能になる。

別Issueとして扱うかは判断が必要。
