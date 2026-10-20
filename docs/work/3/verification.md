# 検証結果: #3 Readyゲートの記録手段をIssueテンプレートへ追加する

- 対象Issue: #3
- 計画: ./plan.md
- 作成日: 2026-10-20

## 実行環境

- 作業ディレクトリ: リポジトリルート
- ブランチ: feature/3
- 環境: darwin-arm64, bash, ruby（YAML解析）, Claude Code 2.1.273

## 受入条件ごとの結果

| 受入条件 | 検証方法 | 期待結果 | 実施結果 |
|---|---|---|---|
| Ready確認欄が表示される | GitHub上でIssue作成 | チェックボックス7項目 | **未検証**。テンプレートはデフォルトブランチからのみ読まれるため、マージ後に確認する |
| 人間がチェックするものだと読み取れる | テンプレートの説明文 | description に明記 | 達成。「チェックを付けるのは人間とする」を記載 |
| 種別ラベルが自動付与される | GitHub上でIssue作成 | usecase / task / bug | **未検証**。同上。ラベル自体は作成済み |
| §4 / §5 に記録場所と判断者が書かれている | 文書の確認 | 記載がある | 達成 |
| issue-analysis の着手可否がReady項目と対応する | SKILL.md の確認 | §5 の項目ごとに示す指示 | 達成 |
| GitHub上で3テンプレートの表示を確認 | 目視 | 3件とも正しく表示 | **未検証**。マージ後に確認する |

マージ前に検証可能な3項目は達成。
残り3項目はいずれもGitHub上の表示に依存し、マージ後の確認が必要。

## 実行した手順とコマンド

### ラベルの新設

```
$ gh label create usecase --description "..." --color "0E8A16"
$ gh label create task --description "..." --color "1D76DB"
$ gh label list
accessibility bug documentation duplicate enhancement
good first issue help wanted invalid question wontfix usecase task
```

`usecase` と `task` が存在することを確認。
`bug` は既存ラベルを流用した。

### Issue Forms スキーマの構造検査

必須キー（name / description / body）、各要素の type の妥当性、
`checkboxes` の options の形、id の重複を確認した。

| ファイル | 結果 |
|---|---|
| bug.yml | OK（labels=bug, body=7件） |
| task.yml | OK（labels=task, body=8件） |
| usecase.yml | OK（labels=usecase, body=9件） |

### Ready項目と §5 の一致

```
$ ./scripts/lint-ready-checklist.sh
正本: docs/standards/issue-management.md §5
使用: ruby

  OK   .github/ISSUE_TEMPLATE/usecase.yml（7項目）
  OK   .github/ISSUE_TEMPLATE/task.yml（7項目）

Ready確認欄: 正本と一致
exit 0
```

### 整合性検査の異常系

`task.yml` の1項目を「受入条件が検証可能である」から
「受入条件が書かれている」へ一時的に書き換えて実行した。

```
  OK   .github/ISSUE_TEMPLATE/usecase.yml（7項目）
  NG   .github/ISSUE_TEMPLATE/task.yml: §5 と一致しません
         テンプレートに無い: 受入条件が検証可能である
         §5 に無い:           受入条件が書かれている
exit 1
```

差分を項目単位で報告することを確認。
項目の順序だけが異なる場合も検出する実装になっている。
書き換えは復元済み。

### 必須チェック

```
$ ./scripts/check.sh
必須チェック: 成功（3件）
exit 0
```

#1 で2件だった必須チェックが3件になった。

## 追加・変更したテスト

このIssueは設定ファイルと文書の変更であり、自動テストの対象外。

検証は次で行った。

- `scripts/lint-syntax.sh`（YAML構文）
- `scripts/lint-ready-checklist.sh`（新規。§5 との一致）
- Issue Forms スキーマの構造検査（ad hoc。常設はしていない）

## 検出した不具合

なし。

## 未実施項目と理由

### GitHub上の表示確認（受入条件3項目）

GitHubはIssueテンプレートをデフォルトブランチからのみ読み込むため、
feature ブランチの状態では表示を確認できない。

マージ後に次を確認する。

1. Issue作成画面に3テンプレートが表示される
2. ユースケースと技術タスクにReady確認欄（7項目）が表示される
3. 作成したIssueに種別ラベルが自動付与される
4. バグ報告にReady確認欄が無い

### Issue Forms スキーマ検査の常設

スキーマの構造検査はその場限りのスクリプトで実施し、
`scripts/` へは追加していない。

`lint-syntax.sh` はYAMLとして妥当かまでを見るため、
GitHub固有のスキーマ違反（不正な type、options の形の誤り）は検出しない。
常設するかは別途判断する。

## 残るリスク

- **AIがチェックを付ける**: Ready確認欄は人間が付けるものと説明文に明記したが、機械的な強制はない。`issue-analysis` SKILL にも「AIが充足と判断した項目を、チェック済みとして扱わない」を明記したが、いずれも指示であり強制ではない
- **既存Issueに欄が無い**: #1〜#10 にはReady確認欄が無い。遡及対応しない判断のため、これらのReady判定は従来どおり人間の判断による
- **派生プロジェクトのラベル不足**: `usecase` と `task` が存在しないリポジトリでは、テンプレートからのIssue作成が失敗する。`issue-management.md` §4 に表を記載したが、利用開始手順への反映は #9 と合わせて判断する
- **GitHub固有スキーマの検証不足**: 上記のとおり
