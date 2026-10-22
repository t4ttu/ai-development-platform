---
name: implementation-planning
description: 分析済みIssueについて変更対象・実装順序・検証・移行を具体化する。実装方針や設計計画を求められたときに使う。
argument-hint: "[Issue番号 | 分析結果のパス]"
disallowed-tools:
  - "Bash(git push *)"
  - "Bash(gh pr create *)"
  - "Bash(gh pr merge *)"
  - "Bash(gh pr close *)"
  - "Bash(gh pr comment *)"
  - "Bash(gh pr review *)"
  - "Bash(gh pr edit *)"
  - "Bash(gh pr ready *)"
  - "Bash(gh release *)"
  - "Bash(gh issue create *)"
  - "Bash(gh issue comment *)"
  - "Bash(gh issue edit *)"
  - "Bash(gh issue close *)"
  - "Bash(gh issue reopen *)"
  - "Bash(gh issue delete *)"
---

# Implementation Planning

## 目的

受入条件を満たす実装と検証を、実行可能な計画にする。

## 入力

対象Issueと分析結果:

$ARGUMENTS

## 参照

- docs/architecture.md
- docs/domain.md
- docs/standards/architecture-guidelines.md
- docs/standards/testing-strategy.md
- docs/work/README.md
- docs/work/<Issue番号>/analysis.md（前工程の分析結果）
- 関連コードとテスト

パスはプロジェクトルートを基準とする。

## 手順

1. docs/work/<Issue番号>/analysis.md を読み、Ready条件と分析結果を確認する。
   存在しない場合は、分析が未実施であることを示す。内容を推測で補わない。
2. 受入条件ごとに必要な変更を整理する。
3. 既存の技術、責務、依存関係を確認する。
4. 方式を選び、重要な選択には代替案と理由を付ける。
5. 既存変更と新規作成予定を分けて示す。
6. データ、インターフェース、依存追加、設定への影響を整理する。
7. テストの種類、ケース、実行方法を決める。
8. 移行が必要なら順序と復旧方法を記載する。
9. 作業順序と完了判定を示す。

## 出力

保存先: `docs/work/<Issue番号>/plan.md`
ひな形: `docs/work/templates/plan.md`

### 目的と範囲

対象内、対象外、前提。

### 実装方針

採用方式、理由、重要な代替案。

### 変更対象

責務・ファイルごとの変更。
存在しないファイルは新規予定と明記する。

### 受入条件と検証

各条件に対応する検証方法と期待結果。

### 作業順序

依存関係を考慮した実装順。

### 移行・運用

データ、設定、互換性、復旧への影響。

### 判断待ち

未解決の判断と、それに依存する作業。

## 完了条件

- plan.md が所定の場所に保存されている
- 全受入条件に実装と検証の方針がある
- 変更範囲が明確である
- 重要な影響と未決事項が明示されている

## 作業範囲

計画だけの依頼ではコードを変更しない。
合意済みの方針を再び承認待ちにしない。
技術スタックが未決の場合、勝手に固定しない。

### 強制されている範囲と、指示にとどまる範囲

| 対象 | 状態 |
|---|---|
| push、PR・Issueへの書き込み | frontmatterで遮断されている |
| コードの変更 | 本文の指示のみ。ツールレベルでは遮断していない |

docs/work/<Issue番号>/plan.md の書き出しに Edit / Write が必要なため、
ファイル変更系ツールを一括で遮断できない。
