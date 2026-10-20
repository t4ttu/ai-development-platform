# 検証結果: #4 Skillの操作制約をfrontmatterで強制する

- 対象Issue: #4
- 計画: ./plan.md
- 作成日: 2026-10-21

## 実行環境

- 作業ディレクトリ: リポジトリルート
- ブランチ: feature/4
- 環境: darwin-arm64, bash, ruby（YAML解析）, Claude Code 2.1.273

## 受入条件ごとの結果

| 受入条件 | 検証方法 | 期待結果 | 実施結果 |
|---|---|---|---|
| `code-review` 実行中に Edit / Write が拒否される | 別セッションでの実行 | 拒否される | **未検証**。frontmatterは次セッション以降に適用される |
| `issue-analysis` 実行中に Edit / Write が拒否される | — | 拒否される | **満たさない（意図的）**。下記参照 |
| `/` メニューに引数のヒントが表示される | 目視 | 表示される | **未検証**。目視確認が必要 |
| frontmatterの設定と本文の記述が一致している | 文書の確認 | 一致 | 達成 |
| 遮断後も本来の出力を生成できる | Skillの実行 | 出力が得られる | **未検証**。別セッションでの確認が必要 |

マージ前に検証できたのは1項目。
frontmatterの適用はセッション境界に依存するため、実動作の確認は別セッションになる。

## 意図的に満たさない受入条件

「`issue-analysis` を実行中に Edit / Write が拒否される」は満たさない。

理由は次の2点である。

1. #2 で `issue-analysis` の出力先を `docs/work/<Issue番号>/analysis.md` と定めた。書き出しに Edit / Write が必要である
2. `disallowed-tools` にパス単位の指定（`Edit(docs/**)`）が使える記載が公式文書に無い。確認できるのはコマンドパターンのみ

Edit / Write を遮断すると #2 で定めた工程間の受け渡しが壊れる。
代わりに外部書き込み系（push、PR書き込み、Issue書き込み）を遮断した。

Issue #4 の受入条件の更新が必要である。

## 実行した手順とコマンド

### 仕様の確認

公式ドキュメント（https://code.claude.com/docs/en/skills）で次を確認した。

| 項目 | 結果 |
|---|---|
| `disallowed-tools` | Skillが有効な間、ツールを利用可能プールから取り除く。次のメッセージで解除 |
| `allowed-tools` | 事前承認であり制限にはならない。列挙しないツールも呼び出せる |
| パス単位の指定 | 記載が無い。コマンドパターン（`Bash(...)`）のみ確認できる |
| `$ARGUMENTS` | 現状の記述で正しい。変更不要 |

`allowed-tools` を制限として使う設計は成立しないことが分かった。

### frontmatter の設定内容

```
$ ruby -ryaml -e '...'  # frontmatterを解析
.claude/skills/code-review/SKILL.md              OK  hint=有 deny=19件
.claude/skills/implementation-planning/SKILL.md  OK  hint=有 deny=15件
.claude/skills/implementation/SKILL.md           OK  hint=有 deny=9件
.claude/skills/issue-analysis/SKILL.md           OK  hint=有 deny=15件
.claude/skills/test-generation/SKILL.md          OK  hint=有 deny=9件
```

5件すべてに `argument-hint` と `disallowed-tools` が設定され、
YAMLとして妥当であることを確認した。

### frontmatter 検査の正常系

```
$ ./scripts/lint-syntax.sh
[SKILL.md の frontmatter]
  OK   .claude/skills/code-review/SKILL.md
  OK   .claude/skills/implementation-planning/SKILL.md
  OK   .claude/skills/implementation/SKILL.md
  OK   .claude/skills/issue-analysis/SKILL.md
  OK   .claude/skills/test-generation/SKILL.md
```

### frontmatter 検査の異常系

2パターンを一時的に作って検出を確認した。いずれも復元済み。

1. `disallowed-tools` をリストからマップへ変更（YAML構文エラー）

```
  NG   .claude/skills/implementation/SKILL.md
       frontmatter のYAMLが不正です: did not find expected key ...
exit 1
```

2. `name` を削除

```
  NG   .claude/skills/implementation/SKILL.md
       name がありません
```

初回の実装ではRubyのバックトレースが出力されたため、
`Psych::SyntaxError` を捕捉してメッセージのみを出すよう修正した。

### 必須チェック

```
$ ./scripts/check.sh
必須チェック: 成功（3件）
exit 0
```

## 追加・変更したテスト

このIssueは設定と文書の変更であり、自動テストの対象外。

`scripts/lint-syntax.sh` へ SKILL.md frontmatter の検査を追加した。
これは #4 が設置する制約そのものを守るための検査である。
frontmatterのYAMLが壊れると遮断設定が静かに失われるため。

## 検出した不具合

### frontmatter 検査のエラー出力（修正済み）

異常系の確認時に、Rubyのバックトレースが5行出力され、
原因が読み取りにくかった。
`Psych::SyntaxError` を捕捉してメッセージのみを出すよう修正した。

### 参照切れ検査の誤検出（修正済み）

本検証記録に公式ドキュメントのURLを書いたところ、
`scripts/lint-docs-references.sh` が外部URLの一部を
プロジェクト内パスとして検出し、必須チェックが失敗した。

```
参照切れ: docs/en/skills
```

原因は、抽出対象の正規表現が `docs/` で始まる文字列を
URLの一部かどうかを区別せずに拾っていたこと。

修正として、抽出前に次を除去する処理を追加した。

1. コードフェンスで囲まれた範囲。コマンド例、ツールの出力、
   ディレクトリ構成の例示が入るため、参照の対象外とする
2. 外部URL。スキーム付きと、スキームの無いホスト名表記の両方

1 が必要になったのは、この検証記録に検査結果をそのまま引用したところ、
引用された文字列が再度「参照切れ」として検出されたためである。
検証記録がツールの出力を引用できないという制約は実用上成立しない。

回帰確認として、外部URLとコードフェンスを含む文書で、
散文中の実在しない `.md` への参照を検出できることを確認した。

#1 で導入したスクリプトの不具合であり、#4 の作業中に3度発見した
（URL誤検出、ホスト名表記、出力の引用）。

## 未実施項目と理由

### 遮断の実動作（受入条件3項目）

frontmatterはセッション開始時およびSkill呼び出し時に読まれる。
本セッションでファイルを作成したため、実際に遮断されるかを判定できない。

別セッションで次を確認する。

1. `/code-review` を実行中に Edit / Write が拒否される
2. `/implementation` を実行中に `git push` が拒否される
3. `/issue-analysis` を実行中に `gh issue comment` が拒否され、`docs/work/` への書き込みは成功する
4. `/` メニューに引数のヒントが表示される
5. 遮断後も各Skillが本来の出力を生成できる

### パス単位の指定の検証

`disallowed-tools: Edit(docs/**)` が機能するかは未確認。
公式文書に記載が無く、実験には別セッションが必要なため見送った。

機能する場合、`docs/work/` 以外への書き込みを遮断する精密な制御が可能になり、
`issue-analysis` の「実装しない」をツールレベルで強制できる。

## 作業上の問題（記録）

### 必須チェックが失敗した状態でコミット・pushした

`check.sh` が exit 1 を返していたにもかかわらず、
コミットとpushを実行した（コミット 6821681）。

原因は、チェックの実行結果を確認せずに次の操作へ進んだこと。
`check.sh` の失敗はコミットをブロックしない（Stop hookは
応答完了時に動作するもので、git操作を止めるものではない）。

### CIでも検出されなかった

`.github/workflows/ci.yml` の `push` トリガーは `main` のみで、
`pull_request` はPRが存在するときに動作する。

featureブランチへpushした時点ではPRが無かったため、
CIが起動せず、失敗した状態のコミットが検出されなかった。

#1 で設置した強制層に、次の経路の穴がある。

| 経路 | CI | Stop hook |
|---|---|---|
| main へのpush | 動作する | — |
| PR作成後のpush | 動作する | — |
| PR作成前のfeatureブランチへのpush | **動作しない** | 応答完了時のみ |

この経路の扱いは別途判断が必要。
`ci.yml` の `push` トリガーを全ブランチへ広げる案がある。

### コミットメッセージのSHA誤記

修正コミット 6ca176e のメッセージで、
直前のコミットを `1e5e4ab` と記載したが、正しくは `6821681` である。

push済みのため履歴は書き換えていない。正しい値はこの記録とする。

## 残るリスク

- **照合の限界**: 遮断はコマンド文字列への照合であり、`git -C . push` や `/usr/bin/git push`、`bash -c 'git push'` は対象外。#1 の deny ルールと同じ限界を持つ。README §5 に明記した
- **`gh api` による迂回**: `gh api -X POST` でIssueへの書き込みが可能。`gh api` を一括遮断すると読み取り用のAPI呼び出しも止まるため、遮断対象に含めていない
- **指示にとどまる範囲**: `issue-analysis` と `implementation-planning` の「コードを変更しない」はツールレベルで強制していない。各SKILL.mdに強制範囲と指示範囲を表で明記したが、誤認のリスクは残る
- **Skill外では無効**: 次のメッセージで解除される。Skillを呼ばずに同じ作業を依頼した場合は遮断されない
- **PR作成前のpushがCIの対象外**: 上記「作業上の問題」のとおり。#1 の強制層の穴である
