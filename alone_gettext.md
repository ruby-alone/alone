# 国際化

--------------------------------------------------------------------------------
## 概要
 * gettext gem を使う (https://rubygems.org/gems/gettext)
 * `_()` 関数を使った翻訳のみで良い場合、実行時のみ Alone独自実装を使うこともできる。
   その場合、gettext gem のインストールは不要。
 * 次のファイルの翻訳メッセージが対象。
    - Ruby (.rb)
    - JavaScript (.js)
    - htmlテンプレート(.rhtml) の `<%= %>` 内の翻訳
	- htmlの `<script>` タグに書かれた JavaScript

 * 技術的な都合により、Ruby と JavaScript は別々の翻訳作業が必要となる。
 * 翻訳作業ワークフローを、付属のRakefileでサポートする。
   ただし、Alone標準ディレクトリ構成に従っている必要がある。
 * サンプルコード `controllers/80_i18n_gettext` があるので、そちらも参照のこと。


--------------------------------------------------------------------------------
# 翻訳ワークフロー

## 準備

### gem の導入
`gettext` gems を導入する。
後述する htmlファイル内の `<script>` タグに含まれる JavaScript コードも対象にする場合は、`nokogiri` も併せて導入する。

### エントリーポイントの修正

エントリーポイント（以下の例では `/htdocs/index.rb`）に、gettext ライブラリの使用を追加する。
```ruby
require_relative '../al_config'
require 'al_gettext'            # 追加
require 'al_controller'
```

### Aloneライブラリ提供の翻訳ファイルのコピー（任意）

Aloneライブラリは、標準で日本語(`ja_JP`)のみ翻訳ファイルを提供しており、その他のロケールの場合は、英語でエラーメッセージ等が表示される。これを多国語化したい場合は、以下の手順により各言語の翻訳ファイルを作る。
```sh
rake gettext_copy_po locale=（ロケール名　例:de_DE）
```

## Rubyコード の翻訳ワークフロー

コントローラとモデルの Ruby コード、および HTML テンプレート中に書かれた動的翻訳対象文字列に対するワークフロー。

1. **Define messages**: メッセージを定義
2. **Extract**: 抽出
3. **Translate**: 翻訳
4. **Compile**: コンパイル

以下、ロケールの例として、「ja_JP」を想定して記述する。

### 1. Define messages.

変換したいメッセージを、`_()` で囲む。

コントローラもしくはモデルの場合
```ruby
@my_message = _("Hello, Ruby!")
```

htmlテンプレートの場合
```erb
<%=h _"Hello, Ruby!" %>
```

### 2. extract.

翻訳テンプレートファイル `/locale/userapp.pot` を生成する。
以下の Rake タスクでこの後の　4. Compile まで一括で行うことができる。
```ruby
rake gettext locale=ja_JP
```

### 3. Translate.

言語ごとの翻訳ファイル `/locale/ja_JP/userapp.po` を編集する。
`msgstr ""` の空文字列に、上の行 (`msgid`) に対応する訳文を入力する。

**userapp.po の例:**
```po
#: （ここへは、ファイル名と行番号が参考情報として挿入される）
msgid "Hello, Ruby!"
msgstr "こんにちは、ルビー！"
```

### 4. Compile.

以下の Rakeタスクでコンパイルする。
```sh
rake gettext locale=ja_JP
```

複数の言語に対応する場合は、2から4までを locale= に別な言語を指定して、再実行する。

> **（参考）個別ステップの実施**
> 各ステップは、別々の Rake タスクでも実施できる。
> * `rake gettext_make_pot`：抽出作業のみを実施
> * `rake gettext_make_po locale=ja_JP`：言語ごとの翻訳ファイルを作成
> * `rake gettext_make_mo locale=ja_JP`：コンパイルのみを実施


## JavaScriptコード の翻訳ワークフロー

htdocs ディレクトリに置かれた JavaScript ファイルに対するワークフロー。

1. **Define messages**: メッセージを定義
2. **Extract**: 抽出
3. **Translate**: 翻訳

オプションで、htmlファイル中の `<script>` タグ内に書かれた JavaScript コードもサポートできる。その場合は、nokogiri gem を導入しておくこと。

### 1. Define messages.

変換したいメッセージを、`_()` で囲む。
```javascript
const my_message = _("Hello, Ruby!");
```

### 2. extract.

翻訳ファイル `htdocs/locale/ja_JP/messages.js` を生成する。
以下のRakeタスクで、実施する。
```sh
rake gettext locale=ja_JP

# htmlファイル中の `<script>` タグも対象にしたい場合
rake gettext locale=ja_JP gettext_js_target=all
```

### 3. Translate.

言語ごとの翻訳ファイル `htdocs/locale/ja_JP/messages.js` を編集する。
`"翻訳対象文字列": "",` と並んでいるので、空文字列に対応する訳文を入れる。

messages.js の例
```javascript
  // ここへは、ファイル名と行番号が参考情報として挿入される）
  "Hello, Ruby!": "こんにちは、ルビー！",
```



--------------------------------------------------------------------------------
# リファレンス

## 翻訳ファイル関連のディレクトリツリー

```
|-- locale                            (User locale directory)
|   |-- userapp.pot
|   `-- ja_JP
|       |-- userapp.po
|       |-- alone.po                  (This takes priority if exist)
|       `-- LC_MESSAGES
|           `-- messages.mo           (User and alone-lib merged)
|-- htdocs
|   `-- locale
|       `-- ja_JP
|           `-- messages.js
|-- lib
|   `-- locale     (Alone locale directory. only alone-lib translation files.)
|       |-- alone.pot
|       `-- ja_JP
|           |-- alone.po
|           `-- LC_MESSAGES
|               `-- messages.mo
```

## 動作仕様

 * User locale directory (/locale) 以下に、ユーザーアプリケーションのための
   翻訳ファイルを置く
 * Alone locale directory (lib/locale) は、Aloneライブラリが提供する locale
   関連ファイルで、ユーザーは変更しない
 * User locale directory が無くても翻訳が行われないだけで、動作に支障はない
 * User locale directory の各言語ディレクトリ（例：ja_JP）以下に、alone.po を置くと
   Alone locale directory の alone.po に優先してこちらを使う。
 * 翻訳作業には gem gettext パッケージに含まれるコマンド群が必要となる。
 * 実行時は、`_()` および `p_()` 関数のみ、Alone独自実装を用意しており、その場合に
   限り gem gettext のインストールは不要。
 * 各ファイル及びディレクトリの作成は Rakefile に手順化している。
 * JavaScript の翻訳は、翻訳ファイルをウェブサーバーで提供するために別管理とし、
   htdocs以下に別途 locale ディレクトリを設置する。
 * オプションで、htmlファイル（テンプレート含む）中の `<script>` タグに書かれた
   JavaScript も対象にできる。その場合、解析のために nokogiri gem が必要。


## 拡張子別ファイル説明

### .pot

 * 翻訳テンプレートファイル
 * `rxgettext` によってソースコードがスキャンされ生成される
 * ソースコードのメッセージに変更があった場合に作り直す必要がある

### .po

 * 翻訳ファイル
 * `rmsginit` によって .pot ファイルから各言語ごとに生成される
 * 実際の翻訳作業では、このファイルを編集する
 * .pot ファイルが作り直された場合、こちらも更新（再編集）が必要
 * 既に .po ファイルがある場合は、`rmsgmerge` で既存の .po と新しい .pot をマージする


### .mo

 * 翻訳ファイルコンパイル結果
 * `rmsgfmt` によって .po ファイルから作られ、各言語の `LC_MESSAGES` ディレクトリ下に
    配置される


## Rubyファイルの多国語対応仕様

gettext gem を使うため、gettext の仕様を踏襲する。


## JavaScriptファイルの多国語対応仕様

gettext の動作を模倣し、以下の仕様で動作する。

 * JSコードに含まれる `_()` 関数で囲まれた文字列を対象に、すべての文字列を翻訳ファイルへ
   抽出する
 * 言語（ロケール）ごとに、翻訳ファイルを作る
 * 翻訳作業は、翻訳ファイルのJSONデータを直接編集する
 * オプションで、htmlテンプレート内の `<script>` タグも対象とする
 * 実行時は、Alone.js 内にグローバルに定義された `_()` 関数が対象ロケールの文字列を取り出す


## Rakefile による実際の作業詳細

### gettext_copy_po
Aloneライブラリメッセージの翻訳ファイルを生成する。

 * Aloneライブラリメッセージの翻訳をする場合にのみ、このタスクを実行する
 * Aloneライブラリで、対象言語の翻訳が提供されている場合は、その .po をコピーし、
   提供がない場合は 空の .po ファイルを作る

```
rake gettext_copy_po locale=ja_JP
```

ソース
 lib/locale/(LOCALE)/alone.po
  もしくは
 lib/locale/alone.pot

出力
 locale/(LOCALE)/alone.po


### gettext_make_pot
ユーザーコード全体をスキャンして、翻訳テンプレート userapp.pot を生成する。

 * ユーザーコードの変更を行った時に実行する

```
rake gettext_make_pot
```

ソース
 controllers/**/*.rb, *.rhtml
 views/**/*.rhtml
 models/**/*.rb

出力
 locale/userapp.pot


### gettext_make_po
メッセージ翻訳ファイルを、言語別に生成する。

 * 新規に言語をサポートする場合に実行する
 * userapp.pot ファイルを作り直した場合に実行する
 * 既に翻訳ファイルが存在する場合は、既存.po ファイルと新.pot ファイルのメッセージを
   マージする

```
rake gettext_make_po locale=ja_JP
```

ソース
 locale/userapp.pot

出力
 locale/(LOCALE)/userapp.po


### gettext_make_mo
メッセージ翻訳ファイルを、言語別にコンパイルする。

 * userapp.po ファイルを作り直した場合に実行する

```
rake gettext_make_mo locale=ja_JP
```

ソース
 locale/(LOCALE)/userapp.po
 lib/locale/(LOCALE)/alone.po
  もしくは
 locale/(LOCALE)/alone.po

出力
 lib/locale/(LOCALE)/LC_MESSAGES/messages.mo



## Alone locale directory のメンテナンス（参考）

### gettext_make_alone_pot
Aloneライブラリ全体をスキャンして、翻訳テンプレート alone.pot を生成する。

 * Aloneライブラリの変更を行った時に実行する

```
rake gettext_make_alone_pot
```

ソース
 lib/**/*.rb

出力
 lib/locale/alone.pot


### gettext_make_alone_po
Aloneライブラリのメッセージ翻訳ファイルを、言語別に生成する。

 * alone.pot ファイルを作り直した場合に実行する
 * 既に翻訳ファイルが存在する場合は、既存 .po ファイルと新 .pot ファイルのメッセージをマージする

```
rake gettext_make_alone_po locale=ja_JP
```

ソース
 lib/locale/alone.pot

出力
 lib/locale/(LOCALE)/alone.po


### gettext_make_alone_mo
Aloneライブラリのメッセージ翻訳ファイルを、言語別にコンパイルする。

 * alone.po ファイルを作り直した場合に実行する

```
rake gettext_make_alone_mo locale=ja_JP
```

ソース
 lib/locale/(LOCALE)/alone.po

出力
 lib/locale/(LOCALE)/LC_MESSAGES/messages.mo
