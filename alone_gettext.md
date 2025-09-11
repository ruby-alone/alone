# 国際化

## 概要
 * gettext ライブラリを使う (https://rubygems.org/gems/gettext)
 * 実行時のみ、Alone独自実装を使うこともでき、gettext のインストールは不要となる


## ディレクトリツリー（国際化関連のみ）
```
(Alone locale directory)
  ./lib/locale/   (alone-lib only translation file)
     |-- alone.pot
     +-- ja_JP/
          |-- alone.po
          +-- LC_MESSAGES/messages.mo

(User locale directory)
  ./locale/       (user programs translation file)
     |-- userapp.pot
     +-- ja_JP/
          |-- userapp.po
          |-- (alone.po)              (This takes priority if exist)
          +-- LC_MESSAGES/messages.mo (User and alone-lib merged)
```

 * ./lib/locale ディレクトリ下のファイルは、Aloneライブラリが提供する
 * ./locale ディレクトリはユーザーアプリケーションのための翻訳ファイルを置く


## 拡張子別ファイル説明

### .pot

 * 翻訳テンプレートファイル
 * `rxgettext` によってソースコードがスキャンされ生成される
 * ソースコードのメッセージに変更があった場合に作り直す必要がある

### .po

 * 翻訳ファイル
 * `rmsginit` によって、.pot ファイルから生成される
 * 各言語ごとのディレクトリが作られ、そこへ各言語ごとに作られる
 * 翻訳作業では、このファイルを編集する
 * .pot ファイルが作り直された場合、こちらも作り直す（再編集）必要がある
 * 既に .po ファイルがある場合、`rmsgmerge` で既存 .po と 新 .pot をマージできる

### .mo

 * 翻訳ファイルコンパイル結果
 * `rmsgfmt` によって、.po ファイルから作られる
 * 各言語ごとに LC_MESSAGES ディレクトリ下に作られる

実際のコマンドを使ってのファイル生成は、すべて Rakefile へ手順化してあるので、そちらを使えば良い。


## 動作仕様

 * Aloneロケールディレクトリは、利用者は変更しない
 * ユーザロケールディレクトリは、あってもなくても良い
 * Aloneが提供するメッセージを変更したい場合、./locale/ja_JP/alone.po 等、コピーしてそちらを変更する
 * Aloneが標準で提供していない言語で Aloneが発するメッセージを翻訳する場合も、上記と同様である
 * 翻訳作業には gem gettext パッケージに含まれるコマンド群が必要となる
 * 実行時は、`_()` および `p_()` 関数のみ、Alone独自実装を用意しており、その場合に限り gem gettext のインストールは不要
 * 各ファイル及びディレクトリの作成は Rakefile に手順化しており、そちらを使う



## Rakefile による実際の作業

Rakefileのタスク

 * gettext_copy_po
 * gettext_make_pot
 * gettext_make_po
 * gettext_make_mo


### gettext_copy_po
Aloneライブラリメッセージの翻訳ファイルを生成する。

 * Aloneライブラリメッセージの翻訳をする場合にのみ、このタスクを実行する
 * Aloneライブラリで指定言語の翻訳が提供されている場合は、その .po をコピーし、提供がない場合は 空の .po ファイルを作る

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
ユーザコード全体をスキャンして、翻訳テンプレート userapp.pot を生成する。

 * ユーザコードの変更を行った時に実行する

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

 * userapp.pot ファイルを作り直した場合に実行する
 * 既に翻訳ファイルが存在する場合は、既存 .po ファイルと新 .pot ファイルのメッセージをマージする

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



## Aloneロケールディレクトリのメンテナンス（参考）

Rakefileのタスク

 * gettext_make_alone_pot
 * gettext_make_alone_po
 * gettext_make_alone_mo


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
