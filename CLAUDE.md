# {{PROJECT_NAME}}

このファイルは、プロジェクトで作業するAIの入口です。

@docs/product.md
@docs/architecture.md
@docs/domain.md

## 1. 作業前の確認

- 対象Issueの目的、受入条件、対象外を確認する。
- 関連する既存コード、テスト、文書を確認する。
- 作業ツリー内の既存変更を確認する。
- 他者の変更や未コミットの作業を無断で消さない。

## 2. 開発標準

必要な工程で次を参照する。

- 開発工程: docs/standards/development-workflow.md
- IssueとReady条件: docs/standards/issue-management.md
- 設計: docs/standards/architecture-guidelines.md
- テスト: docs/standards/testing-strategy.md
- レビュー: docs/standards/code-review.md
- 完了条件: docs/standards/definition-of-done.md

詳細をこのファイルへ重複記載しない。

## 3. RulesとSkills

- Rulesは .claude/rules/ にある。
- Skillsは .claude/skills/ にある。
- Rulesをこのファイルから重複importしない。
- 作業内容に合うSkillを必要に応じて使用する。

## 4. 判断

- 未決の業務仕様を勝手に確定しない。
- 重要な判断には選択肢、影響、推奨案を示す。
- 通常の内部実装は既存設計と規約に沿って判断する。
- 合意済みの範囲について同じ確認を繰り返さない。

## 5. 技術と実行方法

- 技術スタックを推測で固定しない。
- 実行方法と必須チェックはdocs/architecture.mdと実際の設定を確認する。
- 不一致がある場合は調査し、正しい手順へ更新する。
- 未設定のコマンドやCIを実施済みと報告しない。

## 6. 変更と報告

- Issueの範囲を守る。
- 必要なテストと文書を更新する。
- 変更概要、検証結果、未検証範囲、残課題を報告する。
- 実装完了、受入済み、マージ済み、リリース済みを区別する。
