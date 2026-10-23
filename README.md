# {{PROJECT_NAME}}

## このひな形について

Claude Codeを活用したAI駆動開発のための共通基盤です。

開発標準、Rules、Skills、Issue・PRテンプレート、
プロジェクト文書のひな形をまとめています。

特定のプログラミング言語やフレームワークには依存しません。
プロジェクトを生成するスクリプトや、専用の実行環境も不要です。

新規プロジェクトは、このリポジトリから派生させて作ります。
GitHubのテンプレートリポジトリとして公開しており、
テンプレートから作る方式とcloneする方式のどちらでも利用できます（§1）。

## 1. 利用開始

派生元を platform リモートとして残し、基盤の改善を後から取り込める状態にする（§9）。
コミット履歴を共有するかで2つの方式がある。

### 1.1 派生の方式を選ぶ

| | 方式A: 履歴を共有しない | 方式B: 履歴を共有する |
|---|---|---|
| 作り方 | テンプレートから作る、またはcloneして履歴を作り直す | cloneしてplatformリモートを残す |
| アプリの履歴 | アプリのコミットだけ | 根元に基盤の開発履歴が入る |
| 未取り込みの判定 | PLATFORM_BASEの記録を起点に計算する | gitが祖先関係から計算する |
| 記録の維持 | 取り込みのたびにPLATFORM_BASEを更新する | 不要 |
| 判定を誤る条件 | 記録の更新漏れ | なし |

既定は方式A。アプリの履歴にアプリ以外のコミットを入れないため。

取り込みの管理を自動にしたい場合は方式Bを選ぶ。
基盤を頻繁に改善し、その都度取り込む運用では方式Bが向く。

1.4 以降の手順は方式に依存しない。

### 1.2 方式A: 履歴を共有しない

基盤はGitHubのテンプレートリポジトリとして公開している。

```
gh repo create <アプリ名> --template <基盤のリポジトリ> --private --clone
cd <アプリ名>
git remote add platform <基盤のURL>
git remote set-url --push platform DISABLED
git fetch platform
```

基盤の最新のファイルをそのまま引き継ぎたい場合は、
cloneしてから履歴を作り直す。1.4〜1.8 の初期化を済ませてから実行する。

```
git clone <基盤のURL> <アプリ名>
cd <アプリ名>
git remote rename origin platform
git remote set-url --push platform DISABLED
git rev-parse platform/main          # 派生点のSHAを控える
# ここで 1.4〜1.8 の初期化を行う
git checkout --orphan main-fresh
git add -A
git commit -m "chore: 初期コミット"
git branch -D main
git branch -M main-fresh main
git remote add origin <新しいリポジトリのURL>
git push -u origin main
```

#### PLATFORM_BASE を作る

履歴を共有しないため、派生点をファイルで記録する。
リポジトリ直下に `PLATFORM_BASE` を置く。

```
repository=<基盤のURL>
commit=<基盤のコミットSHA>
derived_at=<YYYY-MM-DD>
```

SHAは `git rev-parse platform/main` で得る。

この記録が §9 の起点になる。
取り込みのたびに `commit=` を更新する。
更新を忘れると、取り込み済みの変更が未取り込みとして出続ける。

### 1.3 方式B: 履歴を共有する

```
git clone <基盤のURL> <アプリ名>
cd <アプリ名>
git remote rename origin platform
git remote set-url --push platform DISABLED
git remote add origin <新しいリポジトリのURL>
git push -u origin main
```

`PLATFORM_BASE` は不要。履歴そのものが派生点の記録になる。

### 1.4 基盤の作業記録を外す

platform リモートは残す。削除すると §9 の差分計算ができなくなる。
push URLは無効化し、参照専用として扱う。

基盤側のIssueに対応する作業記録は、新規プロジェクトでは不要。
`docs/work/templates/` は残す。

```
git rm -r --cached docs/work/<基盤のIssue番号>
```

### 1.5 参照の除外リストを初期化する

`scripts/lint-docs-references.sh` の `allowed_missing` を空にする。
基盤のIssue番号が入っているため、そのままでは意味を持たない。

```
allowed_missing=()
```

### 1.6 Issueのラベルを作る

Issueテンプレートは種別ラベルを自動付与する。
ラベルが存在しないとテンプレートからのIssue作成が失敗する。

```
gh label create usecase --color 0E8A16
gh label create task --color 1D76DB
```

`bug` はGitHubの既定ラベルを使う。

### 1.7 必須チェックが通ることを確認する

```
./scripts/check.sh
```

この時点で成功する。技術スタックを決めたら、
テストや型検査を `scripts/check.sh` へ追加する（§7）。

### 1.8 プロジェクトの内容を記載する

1. README.mdとCLAUDE.mdの {{PROJECT_NAME}} を置き換える。
2. docs/product.mdへプロダクトの目的と対象範囲を記載する。
3. docs/domain.mdへ業務用語と業務ルールを記載する。
4. docs/architecture.mdへ技術選定と構成を記載する。
5. 最初のユースケースをIssueにする。
6. プロジェクトルートでClaude Codeを起動する。

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

引数のヒントは `/` メニューに表示される。

### Skillごとに遮断される操作

各SkillのfrontmatterでdisallowedToolsを設定しており、
そのSkillが有効な間は次の操作が遮断される。

| Skill | 遮断される操作 |
|---|---|
| issue-analysis | push、PR・Issueへの書き込み |
| implementation-planning | push、PR・Issueへの書き込み |
| implementation | push、PR作成・マージ、リリース |
| test-generation | push、PR作成・マージ、リリース |
| code-review | 上記に加えて、ファイル変更（Edit / Write / NotebookEdit）とコミット |

issue-analysisとimplementation-planningは、
docs/work/へ成果物を書き出すためファイル変更を遮断していない。
これらが実装を行わないことは本文の指示であり、ツールレベルの強制ではない。

遮断はコマンド文字列への照合であり、プログラムに対する境界ではない。
別形式の呼び出しは対象外になる。

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

固有の追加Rulesは .claude/rules/ へファイルを追加する。
既存ファイルと衝突しない名前にする。

入れ子のディレクトリは読み込みのタイミングが異なるため、
Rulesは .claude/rules/ の直下に置く。

固有Skillsは、既存Skillと衝突しない名前にする。

## 9. 既存プロジェクトへの改善反映

基盤の変更は自動では反映されない。
§1 で選んだ方式に応じて、未取り込みの変更を確認して取り込む。

### 9.1 未取り込みの変更を一覧する

```
git fetch platform
```

#### 方式A: 履歴を共有しない

`PLATFORM_BASE` に記録した派生点を起点にする。

```
git log --oneline $(grep '^commit=' PLATFORM_BASE | cut -d= -f2)..platform/main
```

出力が空なら、記録上は取り込み済みである。
判定は記録の正しさに依存する。`commit=` の更新を忘れていないか確認する。

#### 方式B: 履歴を共有する

```
git log --oneline --cherry-pick --right-only HEAD...platform/main
```

出力が空なら、取り込み済みである。

`--cherry-pick` は、既に取り込んだ変更と内容が同じコミットを除外する。
`...`（3点）と `--right-only` で、基盤側にだけある変更を見る。

単純な `HEAD..platform/main`（2点）は使わない。
cherry-pickで取り込むと新しいコミットが作られるため、
取り込み済みの変更が出続ける。

コミットごとの状態は次で確認できる。

```
git cherry -v HEAD platform/main
```

行頭の `-` は取り込み済み、`+` は未取り込みを示す。

### 9.2 内容を確認する

```
git show <コミット>
git diff HEAD...platform/main -- .claude/ docs/standards/
```

### 9.3 必要な変更だけを取り込む

```
git switch -c platform-update
git cherry-pick <コミット>
```

ファイル一式を無条件に上書きしない。
基盤の変更すべてを取り込む必要はない。

### 9.4 取り込み後に確認する

1. アプリ固有の仕様と矛盾しないか確認する。
2. CLAUDE.md、Rules、Skills、開発標準の整合性を確認する。
3. `./scripts/check.sh` が成功することを確認する。
4. 競合した場合、アプリ側の判断を優先するかを決めて記録する。

方式Aでは、取り込んだ範囲まで `PLATFORM_BASE` の `commit=` を進める。

```
git rev-parse platform/main    # すべて取り込んだ場合はこの値
```

一部だけ取り込んだ場合は、取り込んだ最後のコミットのSHAを記録する。
記録を進めないと、取り込み済みの変更が出続ける。

最後に §9.1 のコマンドで、取り込んだ変更が一覧から消えたことを確認する。

### 9.5 基盤側へ還元する

複数プロジェクトに役立つ変更は、基盤側のIssueとして登録する。
派生プロジェクトから基盤へ直接pushしない。

platform リモートは参照専用として扱う。

## 10. 位置付け

RulesはAIへの指示であり、アクセス制御そのものではない。
Skillsは作業手順であり、人間の受入判断を代替しない。

必要な権限制御、テスト、レビュー、CI、運用設定は、
各プロジェクトで整備する。

## 11. このREADMEの扱い

新規プロジェクトで利用を始めた後は、
プロダクトの概要、利用方法、実行方法への案内を追加する。

ひな形の説明で不要になった部分は整理してよい。
