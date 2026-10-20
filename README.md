# {{PROJECT_NAME}}

## このひな形について

Claude Codeを活用したAI駆動開発のための共通基盤です。

開発標準、Rules、Skills、Issue・PRテンプレート、
プロジェクト文書のひな形をまとめています。

特定のプログラミング言語やフレームワークには依存しません。
プロジェクトを生成するスクリプトや、専用の実行環境も不要です。

新規プロジェクトでは、このフォルダをコピーして利用します。

## 1. 利用開始

1. ai-development-platformフォルダをコピーする。
2. コピー先のフォルダ名をアプリ名へ変更する。
3. README.mdとCLAUDE.mdの {{PROJECT_NAME}} を置き換える。
4. docs/product.mdへプロダクトの目的と対象範囲を記載する。
5. docs/domain.mdへ業務用語と業務ルールを記載する。
6. docs/architecture.mdへ技術選定と構成を記載する。
7. 最初のユースケースをIssueにする。
8. プロジェクトルートでClaude Codeを起動する。

コピーするときは、隠しフォルダの .claude/ と .github/ も含める。

元のai-development-platformフォルダは、次のプロジェクトで使えるように残す。

.gitディレクトリが含まれている場合、それは既存のGit履歴である。
新規プロジェクトへ同じ履歴を引き継ぐかは別途判断する。

## 2. ディレクトリの役割

| 場所 | 役割 |
|---|---|
| CLAUDE.md | AIがプロジェクトを理解する入口 |
| .claude/rules/ | AIが作業中に守るルール |
| .claude/skills/ | 特定の作業を行う手順 |
| .github/ | GitHub Issue・PRのテンプレート |
| docs/product.md | 利用者、目的、機能、対象外 |
| docs/architecture.md | 技術選定、構成、実行・運用方法 |
| docs/domain.md | 業務用語、不変条件、状態、権限 |
| docs/work/ | Issueごとの分析、計画、検証結果 |
| docs/standards/ | 開発工程と品質基準 |

## 3. 最初に決めること

### プロダクト

- 誰が利用するか
- どの課題を解決するか
- 最初に提供する機能
- 今回は作らない機能
- 成功をどう確認するか

### 業務仕様

- 用語
- 入力と出力
- 必ず守る条件
- 権限
- 状態遷移
- 日付、金額、数量などの扱い

### システム

- 必要な技術スタック
- システムの構成
- 保存するデータ
- 外部サービスとの接続
- 実行と検証の方法
- 運用上の制約

決定していない事項は未決と記載する。
ひな形の未決欄を、決定済みの仕様として扱わない。

## 4. 開発の流れ

1. 要求整理
2. Issue作成
3. Issue分析
4. 実装計画
5. 実装
6. テスト
7. コードレビュー
8. 受入確認
9. 完了・振り返り

詳細はdocs/standards/development-workflow.mdを参照する。

## 5. Skillsの利用

| Skill | 用途 |
|---|---|
| issue-analysis | Issueの要求・影響範囲・不明点を整理する |
| implementation-planning | 実装方針と検証方法を計画する |
| implementation | 合意済みのIssueと計画に沿って実装する |
| test-generation | 必要なテストを作成・実行する |
| code-review | 変更差分をレビューする |

呼び出し例:

- /issue-analysis 対象Issueの本文または番号
- /implementation-planning 対象Issueと分析結果
- /implementation 対象Issueと合意済み計画
- /test-generation 対象Issueまたは不具合
- /code-review 対象PRまたは比較範囲

Issue番号だけを渡す場合、Claude CodeがGitHubへアクセスできる必要がある。
接続手段がなければ、Issue本文やローカル文書を渡す。

Skillは工程を支援する手順であり、
全工程を自動実行する仕組みではない。

## 6. GitHubを使用する場合

.github/ISSUE_TEMPLATE/にIssueテンプレートがある。
.github/PULL_REQUEST_TEMPLATE.mdにPRテンプレートがある。

リポジトリへ反映した後、GitHub上で表示を確認する。

GitHubをまだ用意していない場合は、
同じ項目をローカル文書に記載して要求整理や分析を開始できる。

## 7. 実行・検証方法

この基盤では、技術固有のコマンドを固定しない。

採用したシステムに応じて、
docs/architecture.mdへ次を記載する。

- 必要な実行環境
- 初期セットアップ
- アプリの起動方法
- テスト方法
- 型検査・静的解析・ビルド
- CIの必須チェック
- 運用と復旧方法

存在しないコマンドや未設定のCIを、利用可能なものとして記載しない。

### 必須チェックの入口

必須チェックは `scripts/check.sh` へ集約する。

| ファイル | 役割 |
|---|---|
| scripts/check.sh | 必須チェックの単一入口。技術固有のコマンドはここへ書く |
| scripts/lint-syntax.sh | シェル・JSON・YAMLの構文検査。技術非依存のため既定で有効 |
| scripts/lint-docs-references.sh | 文書が参照するパスの実在確認。技術非依存のため既定で有効 |
| scripts/lint-ready-checklist.sh | IssueテンプレートのReady確認欄が正本と一致するかの検査 |
| .claude/settings.json | 破壊的操作のdenyルールと、check.shを実行するStop hook |
| .claude/hooks/required-checks.sh | Stop hookの本体。結果を報告し、失敗時はブロックする |
| .github/workflows/ci.yml | pushとpull requestでcheck.shを実行する |

技術非依存の2件（構文検査と参照切れ検査）は既定で有効になっている。
技術スタックを決めたら、テストや型検査を `scripts/check.sh` へ追加する。

`scripts/check.sh` に1件もチェックが定義されていない場合は
終了コード2（未設定）を返す。これは成功ではない。

コピー後は `scripts/lint-docs-references.sh` の
`allowed_missing`（意図的に未作成とする参照の一覧）を空にする。

設定手順はdocs/architecture.md §10を参照する。

denyルールはAIが通常書く形式のコマンドを止めるものであり、
プログラムに対する強制的な境界ではない。
実行環境レベルの制限が必要な場合は、別途sandboxや権限設定で行う。

## 8. 共通改善と固有変更

### 共通改善

複数プロジェクトに役立つ変更は、
元のai-development-platformへ反映する。

例:

- Issue分析で確認する項目の改善
- 完了条件の明確化
- レビュー手順の改善

### プロジェクト固有の変更

そのアプリだけの仕様は、コピー先のプロジェクトで管理する。

例:

- 金額の上限
- 利用者の権限
- 採用したフレームワーク
- プロジェクト固有のテスト方法

固有の追加Rulesは .claude/rules/local/ に置いてもよい。
固有Skillsは、既存Skillと衝突しない名前にする。

## 9. 既存プロジェクトへの改善反映

コピー後のプロジェクトと元の基盤は独立している。
元の基盤を変更しても、自動では反映されない。

反映するときは次を確認する。

1. 基盤側の変更内容を確認する。
2. コピー先の変更との差を比較する。
3. アプリ固有の仕様と矛盾しないか確認する。
4. 必要な変更だけを取り込む。
5. CLAUDE.md、Rules、Skills、開発標準の整合性を確認する。

ファイル一式を無条件に上書きしない。

## 10. 位置付け

RulesはAIへの指示であり、アクセス制御そのものではない。
Skillsは作業手順であり、人間の受入判断を代替しない。

必要な権限制御、テスト、レビュー、CI、運用設定は、
各プロジェクトで整備する。

## 11. このREADMEの扱い

新規プロジェクトで利用を始めた後は、
プロダクトの概要、利用方法、実行方法への案内を追加する。

ひな形の説明で不要になった部分は整理してよい。
