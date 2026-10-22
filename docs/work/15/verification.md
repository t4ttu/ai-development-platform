# 検証結果: #15 コピー経路の不具合を修正する

- 対象Issue: #15
- 計画: ./plan.md
- 作成日: 2026-10-23

## 実行環境

- 作業ディレクトリ: リポジトリルート、および再現用のコピー先
- ブランチ: feature/15
- 環境: darwin-arm64, GNU bash 3.2.57, ruby, python3, Claude Code 2.1.273

## 受入条件ごとの結果

| 受入条件 | 実施結果 |
|---|---|
| `allowed_missing` を空にして `lint-docs-references.sh` が exit 0 | 達成 |
| `allowed_missing` を空にして `check.sh` が exit 0 | 達成 |
| `docs/adr/` が存在し、項目が §11 と一致する | 達成。10項目すべて対応 |
| `.claude/rules/local/` の参照切れが解消している | 達成。慣例を廃止 |
| シェルスクリプトが無い状態で未定義変数エラーが出ない | 達成。要素数で分岐 |
| 本物の参照切れは引き続き検出される | 達成 |
| 空配列の注意が各スクリプトに記載されている | 達成 |

全7項目を達成した。

## 実行した手順とコマンド

### bash 3.2 の挙動確認

```
$ bash --version
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)

$ bash -c 'set -uo pipefail; a=(); echo "${#a[@]}"'
0

$ bash -c 'set -uo pipefail; a=(); for x in "${a[@]}"; do :; done'
bash: a[@]: unbound variable

$ bash -c 'set -uo pipefail; a=(); echo "${a[*]}"'
bash: a[*]: unbound variable
```

要素数の参照は安全、展開は危険であることを確認した。

### 修正前の再現

```
$ ./scripts/lint-docs-references.sh   # allowed_missing を空にした状態
./scripts/lint-docs-references.sh: line 34: allowed_missing[@]: unbound variable
exit=1
```

### ADRテンプレートの項目一致

`architecture-guidelines.md` §11 の記載項目を抽出し、
テンプレートの見出しと突き合わせた。

```
§11の項目: タイトル, 状態, 背景, 制約, 選択肢, 決定, 理由,
          利点と不利益, 検証方法, 関連Issue
すべて対応している（10項目）
```

### git管理外でのファイル列挙（不具合3の再現と修正確認）

修正前の挙動。

```
$ cd <git管理外のディレクトリ>
$ git ls-files '*.json'
fatal: not a git repository (or any of the parent directories): .git
$ echo $?
0
```

終了コードに現れないため、対象0件となり検査が通過していた。

修正後は列挙方法を出力し、`find` へ切り替わる。

### 新規プロジェクトの再現（最終確認）

README §1 の手順を再現した。

1. `.git` を除外してコピー（`.claude/` と `.github/` を含む）
2. `docs/work/` のIssue別ディレクトリを除外（`templates/` は残す）
3. `{{PROJECT_NAME}}` を置換
4. `allowed_missing` を空にする
5. `git init` はしない（最悪条件）

結果。

```
--- allowed_missing ---
allowed_missing=()
--- docs/work の中身 ---
README.md
templates
--- git管理か ---
fatal: not a git repository (or any of the parent directories): .git

=== 新規プロジェクトで必須チェック ===
ファイル列挙: find
  未実施: shellcheck が未導入です。構文検査(bash -n)のみ実施しました。
--- 構文検査（シェル・JSON・YAML）: 成功 ---
--- 文書の参照切れ検査: 成功 ---
--- Ready確認欄の整合性検査: 成功 ---
必須チェック: 成功（3件）
check.sh exit=0
```

検査されたファイル数は16件で、git管理下と同じ範囲を確認できている。
JSON 1件、YAML 5件、SKILL.md 5件、シェル 5件。
「対象なし」で素通りしていないことを確認した。

### 回帰確認

修正後も本物の参照切れを検出することを確認した
（散文中の実在しないパス、フェンス内は無視、外部URLは無視）。

## 追加・変更したテスト

自動テストの対象外。
再現用のコピーを作って `check.sh` を実行する手順で検証した。

この再現手順は常設していない。常設の是非は別途判断する。

## 検出した不具合

Issue本文に挙げた2件に加え、調査中に3件目を発見した。

### git管理外で検査が黙って通過する（修正済み）

上記のとおり。`git ls-files` の失敗が終了コードに現れず、
JSON・YAML・SKILL.md frontmatter の検査が「対象なし」として
成功のまま通過していた。

#1 の「未検証を成功として扱わない」という前提が、
コピー直後の状態では成立していなかった。

## 未実施項目と理由

- **shellcheck**: ローカル未導入のため未実施として報告される。CI（ubuntu-latest）では実行される
- **コピー手順の文書化**: README §1 に、今回実施した手順（`docs/work/` の整理、`allowed_missing` の初期化、`git init`、ラベル作成）が記載されていない。#9 で利用開始手順を書き換える際に反映する
- **再現手順の常設**: 新規プロジェクトの再現を自動化していない。手動確認にとどまる

## 残るリスク

- **bash 3.2 固有**: Linux の CI では空配列の展開が通るため、この種の不具合はCIで検出できない。ローカル（macOS）でのみ落ちる。同じ書き方が再発しても気付きにくい
- **find のフォールバックの除外漏れ**: `node_modules` `vendor` `dist` `build` `.venv` `target` を除外したが、他の生成物ディレクトリを持つ技術スタックでは誤検出しうる。その場合は `git init` 済みであれば `git ls-files` が使われる
- **再現手順が手動**: コピー経路の回帰を機械的に検出できない
