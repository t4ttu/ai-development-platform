# 実装計画: #15 コピー経路の不具合を修正する

- 対象Issue: #15
- 分析: Issue #15 本文に記載済み
- 作成日: 2026-10-23

## 目的と範囲

README §1 の手順どおりにコピーした新規プロジェクトで、
`scripts/check.sh` が追加作業なしで成功する状態にする。

対象外:

- `.env.example` と秘密管理の既定方針（#10）
- `config.yml` と `usecase.yml` の必須項目見直し（#10）
- 利用開始手順の書き換え（#9 で扱う）

## 調査で追加に判明した不具合

Issue本文に挙げた2件の調査中に、3件目を発見した。

### git管理外で検査が黙って通過する

`scripts/lint-syntax.sh` はJSON・YAMLの列挙に `git ls-files` を使っていた。
git管理外では次の挙動になる。

```
$ git ls-files '*.json'
fatal: not a git repository (or any of the parent directories): .git
$ echo $?
0
```

標準エラーへ出力されるが、`while read` のパイプラインでは
終了コードに現れない。結果として対象0件となり、
検査が「対象なし」として**成功のまま通過する**。

コピー直後で `git init` していない状態がこれに該当する。
#1 の「未検証を成功として扱わない」という前提が崩れる。

これは本Issueの対象範囲（コピー経路の不具合）に含まれるため、
同じ対応に含める。

## 実装方針

### 空配列の展開（不具合1）

bash 3.2 では `set -u` のもとで `"${arr[@]}"` と `"${arr[*]}"` が
未定義変数エラーになる。`${#arr[@]}` は安全。

展開前に要素数で分岐する方式を採る。
`${arr[@]+"${arr[@]}"}` の書き方でも回避できるが、
読み手に意図が伝わりにくいため採らない。

各スクリプトのヘッダへ、この制約を明記する。

### 参照先の作成（不具合2）

| 参照先 | 対応 |
|---|---|
| `docs/adr/` | `0000-template.md` を追加。項目は `architecture-guidelines.md` §11 の10項目に対応させる。テンプレート自体はADRではない旨を明記 |
| `.claude/rules/local/` | 慣例を廃止する。README §8 の記述を `.claude/rules/` 直下へ変更 |

`.claude/rules/local/` を廃止する理由は3点。

1. 入れ子の `.claude/rules/` は無条件ロードではなくオンデマンド読み込みで、直下のファイルと挙動が異なる
2. 参照切れの原因になっている
3. `.claude/rules/` 直下へファイル名で追加すれば目的を満たせる

### ファイル列挙（不具合3）

git管理下では `git ls-files` を使い `.gitignore` を尊重する。
git管理外では `find` で列挙し、生成物ディレクトリを除外する。

どちらを使ったかを出力する。検査範囲が分かるようにするため。

## 変更対象

| ファイル | 変更 |
|---|---|
| `scripts/lint-docs-references.sh` | `allowed_missing` のガード、ヘッダへ注意、除外リストの内容を実態へ |
| `scripts/lint-syntax.sh` | shellcheckループのガード、ファイル列挙をgit非依存化、ヘッダへ注意 |
| `scripts/check.sh` | `failed_labels` のガード |
| `docs/adr/0000-template.md` | 新規 |
| `README.md` §8 | `.claude/rules/local/` の慣例を廃止 |

## 受入条件と検証

Issue本文の7項目に加え、不具合3件それぞれの異常系を確認する。

検証は、README の手順どおりに作ったコピーで `check.sh` を実行して行う。
git管理外の状態（`git init` 前）を再現する。

## 作業順序

1. ADRテンプレートを追加し、§11 との項目一致を確認
2. 空配列のガードを3箇所へ適用
3. README §8 の慣例を変更
4. ファイル列挙をgit非依存化
5. コピー先を再現して `check.sh` を実行

## 移行・運用

既存の派生プロジェクトは無いため移行不要。

`.claude/rules/local/` の廃止は README の記述変更のみで、
実体が無いため影響は無い。

## 判断待ち

なし。Issue本文の未決（`.claude/rules/local/` の扱い）は
慣例の廃止として解消した。
