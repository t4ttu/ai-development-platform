# AI駆動開発基盤

Claude Codeを主軸として、複数のアプリケーションで再利用する開発基盤。

開発標準、AI向けRules、作業手順を定義したSkills、プロジェクトテンプレート、
生成・更新・検証スクリプトを管理する。

## 1. 目的

- 開発工程と品質基準を共通化する
- AIと人間の責任分担を明確にする
- プロジェクトごとの初期設定を減らす
- 共通の改善を複数プロジェクトへ配布する
- アプリ固有情報と共通知識を分離する

このリポジトリ自体に、個別アプリの業務機能は実装しない。

## 2. 管理対象

| ディレクトリ | 役割 |
|---|---|
| standards/ | 人間とAIが従う開発工程・品質基準 |
| rules/ | 各プロジェクトへ配布するAI向けルールの原本 |
| skills/ | 各プロジェクトへ配布する作業手順の原本 |
| templates/project-base/ | 全スタック共通の初期ファイル |
| templates/stacks/ | 技術スタック別の初期構成 |
| scripts/ | 生成・更新・検証処理 |
| tests/ | 基盤の自動テスト |
| examples/ | アプリへの適用例 |

## 3. 必要環境

### 基盤の利用

- Python 3.9以上
- Python標準ライブラリのみで動作
- Gitは履歴管理に推奨するが、生成処理の必須条件ではない

### 生成したアプリの実行

- Next.js: Node.js 20.9以上、npm
- FastAPI: Python 3.10以上
- AIによる開発: Claude Code

アプリの依存パッケージは生成後に導入する。
初回に解決した依存をlockfile等で固定し、プロジェクトで管理する。

## 4. プロジェクト生成

基盤ルートで実行する。

```sh
python3 scripts/create_project.py ../my-app \
  --name my-app \
  --stack nextjs-fastapi
```

選択可能なスタック:

- nextjs
- fastapi
- nextjs-fastapi

生成先には、存在しないディレクトリを指定する。
既存ディレクトリへの上書きや既存プロジェクトへの自動取り込みは行わない。

プロジェクト名は、英小文字で始まる63文字以内の英小文字・数字・ハイフン。
日本語の表示名は生成後のproduct.mdやUIに記載する。

Windowsでは、必要に応じて `python3` を `py -3` に読み替える。

書き込み前に内容を確認する場合:

```sh
python3 scripts/create_project.py ../my-app \
  --name my-app \
  --stack nextjs-fastapi \
  --dry-run
```

## 5. 生成時の配布

| 原本 | 生成先 |
|---|---|
| rules/*.md | .claude/rules/*.md |
| skills/* | .claude/skills/* |
| standards/*.md | docs/standards/*.md |
| project-base/* | プロジェクトの同じ相対位置 |
| スタック別ファイル | スタックに応じた位置 |

Next.js専用ルールはNext.jsを含むプロジェクトに配布する。
Python専用ルールはFastAPIを含むプロジェクトに配布する。

nextjs-fastapiでは、次のように配置する。

- Next.js: apps/web/
- FastAPI: apps/api/

templates/project-base/.claude/は配布先の位置を示す。
Rules・Skillsの本文はここへ重複保存せず、rules/とskills/を原本とする。

## 6. 生成後の開発手順

1. docs/product.mdに対象ユーザー、目的、MVP、対象外を記載する。
2. docs/domain.mdに業務用語と不変条件を記載する。
3. docs/architecture.mdに責務、技術選定、運用方法を記載する。
4. docs/stack.mdに従って依存を導入し、起動と検証を行う。
5. ユースケースをIssueへ分割し、受入条件を定義する。
6. プロジェクトルートでClaude Codeを起動する。
7. 必要な工程でSkillsを利用する。
8. テスト、レビュー、受入を行い、DoDを満たして完了する。

Skillsの呼び出し例:

```text
/issue-analysis 対象Issueの本文または番号
/implementation-planning 対象Issueと分析結果
/implementation 対象Issueと合意済み計画
/test-generation 対象Issueまたは不具合
/code-review 対象PRまたは比較範囲
```

番号だけを渡す場合、AIがGitHubへアクセスできる必要がある。
接続手段がなければIssue本文を渡す。

## 7. アプリ固有情報の置き場所

- product.md: 利用者、提供価値、機能、対象外
- architecture.md: システム構成、技術選定、実行・運用方法
- domain.md: 業務用語、不変条件、状態遷移、権限

固有の追加Rulesは `.claude/rules/local/` に置く。
固有の追加Skillsは、共通Skill名と衝突しない名前にする。

家計簿の金額制約など、特定アプリだけの知識を共通Rulesへ入れない。

## 8. 共通ファイルの更新

原本を修正し、基盤テストを実行した後に配布する。

```sh
python3 scripts/update_project.py ../my-app --dry-run
python3 scripts/update_project.py ../my-app
python3 scripts/validate_project.py ../my-app --strict
```

更新対象:

- .claude/rules/
- .claude/skills/
- docs/standards/
- docs/stack.md

次のファイルは初回生成後に自動更新しない。

- アプリのコード
- 依存パッケージ設定
- CLAUDE.md
- product.md、architecture.md、domain.md
- GitHub Issue/PRテンプレート
- README.md

これらは生成後にプロジェクト側が管理する。

## 9. 更新時の競合

配布時のSHA-256を `.ai-platform/manifest.json` に記録する。
このファイルはGitで追跡する。

更新では次の3つを比較する。

1. 前回配布した内容
2. 現在のプロジェクト内の内容
3. 新しい原本

未編集の管理ファイルは更新する。
管理ファイルの手編集・手削除や、新規配布先との衝突を検出した場合、
更新全体を中止する。

既に新しい原本と同じ内容になっている場合は受け入れる。
同じ状態で再更新しても、不要な書き込みは行わない。

競合を解消するときは、差分を保存してから次のどちらかを行う。

- 共通改善: 原本へ取り込み、配布先も同じ内容へ揃える
- アプリ限定の改善: 固有Rules等へ移し、管理ファイルを原本へ揃える

強制上書きオプションは設けない。

## 10. バックアップと復旧

更新前に、変更対象の旧ファイルを次へ保存する。

```text
.ai-platform/backups/<ID>/files/
```

operations.jsonには、復元対象と更新で新規作成したファイルを記録する。

通常の書き込みエラーでは、適用済みのファイルを復元する。
電源断、強制終了、復元先への書き込み不能まで完全には保証しない。

手動復旧する場合:

1. 更新後に追加した編集を別途保存する。
2. files/配下のファイルを同じ相対位置へ戻す。
3. operations.jsonのcreatedにあるファイルを確認する。
4. 更新で新規作成された不要ファイルを削除する。
5. validate_project.pyで確認する。

同じプロジェクトへの並行更新には対応しない。
シンボリックリンクを含む配布パスは拒否する。

macOSで /tmp 等を使用する場合は、実体パスの /private/tmp を指定する。

## 11. 検証

```sh
python3 -m unittest discover -s tests -v
python3 scripts/validate_project.py ../my-app
python3 scripts/validate_project.py ../my-app --strict
```

通常の検証では、ローカル編集や原本との差を警告する。
--strictでは警告もエラーとして扱う。

検証対象:

- 必須ファイル
- 管理対象ファイルの存在
- 配布履歴との整合性
- 原本との差
- この基盤で採用する限定形式のRules/Skills frontmatter
- CLAUDE.mdの単独行@import参照

アプリの動作テスト、任意のYAML、独自Skillの意味的な正しさ、
セキュリティ全体を保証するものではない。

終了コード:

- 0: 成功
- 1: 検証失敗、競合、ファイル操作エラー
- 2: コマンド引数の誤り

## 12. Claude Codeとの対応

この基盤は次の公式配置を使用する。

- プロジェクト指示: CLAUDE.md
- Rules: .claude/rules/*.md
- Skills: .claude/skills/<name>/SKILL.md
- 条件付きRules: paths frontmatter
- 文書の読み込み: CLAUDE.mdの相対@import

公式資料:

- https://code.claude.com/docs/en/memory
- https://code.claude.com/docs/en/skills

利用開始時は、Claude Code上で指示ファイルとSkillsの認識を確認する。
個人設定や同名コマンドとの競合があれば、実際のコマンド一覧を確認する。

RulesはAIへの指示であり、強制的なアクセス制御ではない。
実行権限、CI、レビュー、運用環境の制約は別途設定する。