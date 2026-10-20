# 検証結果: #2 工程間の成果物の置き場を確定し、Skillを連鎖させる

- 対象Issue: #2
- 計画: ./plan.md
- 作成日: 2026-10-20

## 実行環境

- 作業ディレクトリ: リポジトリルート
- ブランチ: feature/2
- 環境: darwin-arm64, bash, Claude Code 2.1.273

## 受入条件ごとの結果

| 受入条件 | 検証方法 | 期待結果 | 実施結果 |
|---|---|---|---|
| §8 に成果物の正本が1つだけ記載されている | 文書と grep | 二択の記述が無い | 達成。`Issueコメントまたは` の出現 0件 |
| `docs/work/` が存在し、構成と役割が説明されている | 文書の確認 | 配置と役割の表がある | 達成。README.md に §2 配置、§3 役割の表 |
| issue-analysis を実行すると所定の場所に書き出される | Skillを実際に実行 | `docs/work/<番号>/analysis.md` が生成される | 達成。#10 を対象に実行し `docs/work/10/analysis.md` を生成 |
| 新セッションで分析結果が貼り直し不要で参照される | 新セッションでの実行 | 前工程の成果物を参照する | **未検証**。別セッションでの確認が必要 |
| 各SKILL.mdに前工程の成果物のパスが記載されている | grep | 5ファイルすべてに記載 | 達成。下表のとおり |
| Issueから成果物、成果物からIssueへ辿れる | 文書とIssueの確認 | 双方向のリンク | 達成。下記のとおり |

## 実行した手順とコマンド

### SKILL.md への記載（受入条件5）

```
$ for f in .claude/skills/*/SKILL.md; do grep -c 'docs/work' $f; done
```

| Skill | docs/work の参照箇所 |
|---|---|
| issue-analysis | 5 |
| implementation-planning | 5 |
| implementation | 7 |
| test-generation | 7 |
| code-review | 3 |

5ファイルすべてに、参照・手順・出力のいずれかとして記載されている。

### 双方向リンク（受入条件6）

成果物からIssueへ: `対象Issue: #<番号>` を持つファイル

```
docs/work/10/analysis.md
docs/work/2/plan.md
docs/work/templates/analysis.md
docs/work/templates/plan.md
docs/work/templates/verification.md
```

`docs/work/README.md` はIssueに紐づかないディレクトリ説明のため対象外。

IssueからPRおよび成果物へ: `issue-management.md` §10 に
「作業記録との関連付け」を追加し、2箇所で `docs/work/` を参照している。

### Skillの実行（受入条件3）

`/issue-analysis #10` を実行した。

- 更新後のSKILL.mdが読み込まれ、手順10（成果物の書き出し）と保存先が反映されていることを確認
- `docs/work/10/analysis.md`（125行）が生成された
- 分析の過程で、Issue #10 の記載誤り2件を検出した（下記）

### 必須チェック

```
$ ./scripts/check.sh
必須チェック: 成功（2件）
exit 0
```

構文検査、文書の参照切れ検査ともに成功。

### 参照切れ検査が検出した問題（修正済み）

`docs/work/` の作成に伴い、検査が2件を正しく検出した。

1. `allowed_missing` の `docs/work/` が実在するようになった
   → 「例外リストから削除できます」と報告されたため削除
2. `docs/work/README.md` の例示が、実在しない具体的なIssue番号付きの
   パスになっていた
   → 参照切れとして検出。例示を `<Issue番号>` のプレースホルダ表記へ変更し、
     例示の書き方の規約を `lint-docs-references.sh` の冒頭へ明記

   なお本検証記録の作成時にも、同じ具体パスを引用して同じ検出を受けた。
   実在しないパスは、文書内で引用する場合もプレースホルダ表記にする。

#1 で導入した参照切れ検査が、#2 の作業中に実際に機能した事例である。

## 追加・変更したテスト

このIssueは文書とSkill定義の変更であり、自動テストの対象外。
検証は `scripts/check.sh`（構文検査、参照切れ検査）と
Skillの実行による確認で行った。

## 検出した不具合

### Issue #10 の記載誤り（2件）

#10 の分析中に発見した。`docs/work/10/analysis.md` に記録済み。

1. 受入条件に `/doctor prompt-audit` の実行を含めているが、
   当該コマンドは v2.1.283 以降が必要で、現環境は v2.1.273。実行できない。
   #1 で導入した `scripts/lint-docs-references.sh` へ差し替える必要がある
2. 「`usecase.yml` は7項目中6項目が必須」と記載しているが、
   実際は8項目中7項目が必須である

## 未実施項目と理由

- **新セッションでの工程連鎖の確認**: 同一セッション内では、前工程の成果物を
  ファイルから読んだのか文脈から参照したのかを区別できない。
  別セッションで `implementation-planning` を実行し、
  `docs/work/<番号>/analysis.md` を読むことを確認する必要がある

## 残るリスク

- **テンプレートとSKILL.mdの乖離**: テンプレートの見出しとSKILL.mdの「出力」の
  見出しを一致させているが、機械的な整合性検査は無い。
  一方を変更した際にもう一方が取り残される可能性がある
- **成果物の未作成**: `docs/work/README.md` §5 で「必要になった時点で作る」と
  しているため、作成されないことが許容される。
  作らなかった理由の記載も規約であり、強制ではない
- **#4 との競合**: `issue-analysis` に `disallowed-tools` を設定する場合、
  `docs/work/` への書き込みを許可する必要がある。plan.md に制約として記録済み
