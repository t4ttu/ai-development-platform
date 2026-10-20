# 実装計画: #3 Readyゲートの記録手段をIssueテンプレートへ追加する

- 対象Issue: #3
- 分析: Issue #3 本文に記載済み（docs/work/README.md §5 に従い analysis.md は作成していない）
- 作成日: 2026-10-20

## 目的と範囲

`development-workflow.md` §5 の最重要ルール「IssueがReadyになる前に実装を開始しない」に、
記録手段を与える。

現状、`issue-management.md` §5 にReady条件が7項目定義されているが、
どのIssueテンプレートにも含まれていない。
状態管理は §4 で「プロジェクトで設定する」と委ねられており、
基盤側にReadyを記録する場所が存在しなかった。

対象外:

- GitHub Projects のボード設定やワークフロー自動化
- ラベルによる状態遷移の自動化

## 解消した未決事項

| 未決事項 | 決定 | 理由 |
|---|---|---|
| Ready確認欄を入れるテンプレート | usecase と task の2件 | バグ報告の摩擦を増やさない。バグは再現手順と影響範囲が揃えば着手できる |
| ラベル体系 | 種別のみ（usecase / task を新設、bug は既存を流用） | テンプレートで確定するものだけを自動化する。状態はテンプレートでは決まらない |
| Readyの表現 | Issue本文のチェック状態のみ | 正本を1箇所にする。ラベルと本文の二重管理を避ける |

状態ラベル（status:ready など）は導入しない。
`development-workflow.md` §8 の「同じ情報を複数箇所で正本として管理しない」に従う。

## 実装方針

### Ready条件の正本は §5、テンプレートはその写し

7項目の定義は `issue-management.md` §5 を正本とし、
テンプレートの `checkboxes` はその写しとする。

この構成は乖離のリスクを持つ（#6 と同じ構造）。
片方だけが更新されるとゲートが正本と食い違うため、
整合性検査を自動化する。

### チェックを付けるのは人間

`required: true` は使わない。Issue作成時点では未チェックでよい。
Backlog として登録し、条件が満たされた時点で人間がチェックする。

AIは `issue-analysis` の出力として各項目の充足状況と根拠を示すが、
チェックは付けない。

## 変更対象

| ファイル | 変更 |
|---|---|
| `.github/ISSUE_TEMPLATE/usecase.yml` | `labels: usecase` と Ready確認欄（7項目）を追加 |
| `.github/ISSUE_TEMPLATE/task.yml` | `labels: task` と Ready確認欄（7項目）を追加 |
| `.github/ISSUE_TEMPLATE/bug.yml` | `labels: bug` のみ追加。Ready確認欄は入れない |
| `docs/standards/issue-management.md` | §4 に種別ラベルの表、§5 に記録場所と判断者、バグIssueの扱い |
| `.claude/skills/issue-analysis/SKILL.md` | 着手可否の出力を §5 の項目ごとの充足状況へ |
| `scripts/lint-ready-checklist.sh` | 新規。§5 とテンプレートの一致を検査 |
| `scripts/check.sh` | 上記を必須チェックへ登録 |
| `docs/architecture.md` §10 / `README.md` §7 | 検査の表へ追加 |
| GitHubリポジトリ | `usecase` と `task` ラベルを新設 |

### 範囲の追加について

`scripts/lint-ready-checklist.sh` はIssue本文の対象範囲に含まれていない。

追加した理由は、Ready条件が §5 とテンプレートの2箇所に存在する構成を
採ったためである。乖離を検出する手段が無いと、
本Issueが設置するゲート自体が正本と食い違う。

Issue本文の「互換性・移行・運用・リスク」に挙げた
「チェックボックスが増えるとAIが内容を確認せずにチェックを付ける懸念」とは
別のリスクであり、本Issueの成果物を守るための追加である。

## 受入条件と検証

| 受入条件 | 検証方法 | 期待結果 |
|---|---|---|
| テンプレートからIssueを作成するとReady確認欄が表示される | GitHub上でIssue作成画面を開く | チェックボックス7項目が表示される |
| 人間がチェックするものだと読み取れる | テンプレートの説明文 | description に明記されている |
| 種別ラベルが自動付与される | GitHub上でIssueを作成する | usecase / task / bug が付く |
| §4 / §5 に記録場所と判断者が書かれている | 文書の確認 | 記載がある |
| issue-analysis の着手可否がReady項目と対応する | SKILL.md の確認 | §5 の項目ごとに示す指示がある |
| GitHub上で3テンプレートの表示を確認している | GitHub上での目視 | 3件とも正しく表示される |

### 検証上の制約

GitHubはIssueテンプレートを**デフォルトブランチからのみ**読み込む。
このためテンプレートの表示確認は、マージ後にしか実施できない。

マージ前に実施できるのは次の範囲とする。

- YAML構文の検査（`scripts/lint-syntax.sh`）
- Issue Forms スキーマの構造検査（必須キー、type の妥当性、options の形）
- Ready項目と §5 の一致検査（`scripts/lint-ready-checklist.sh`）

## 作業順序

1. `usecase` と `task` ラベルを新設（テンプレートの `labels:` は実在するラベルを要求する）
2. 3テンプレートへ `labels:` を追加、2テンプレートへ Ready確認欄を追加
3. スキーマと項目一致をローカル検証
4. `lint-ready-checklist.sh` を作成し `check.sh` へ登録
5. `issue-management.md` §4 / §5 と `issue-analysis` SKILL を更新
6. 必須チェックを実行
7. マージ後にGitHub上の表示を確認

## 移行・運用

- 既存Issue（#1〜#10）にはReady確認欄が追加されない。遡及対応は行わない
- 派生プロジェクトでは `usecase` と `task` ラベルを各自で作成する必要がある。ラベルが存在しないとテンプレートからのIssue作成が失敗する
- `issue-management.md` §5 の項目を変更する場合は、テンプレート側も同時に更新する。検査が不一致を検出する

## 判断待ち

なし。未決3件は解消済み。

### 派生プロジェクトへの申し送り

ラベルの事前作成が必要であることを、README §1 の利用開始手順へ
追記するかは #9（改善反映の方式）と合わせて判断する。
本Issueでは `issue-management.md` §4 の表に記載するにとどめた。
