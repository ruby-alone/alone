#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# 設定情報保存ファイル
# 必要に応じて書き換えること。

# Aloneライブラリのサーバー上での設置パス
AL_BASEDIR = "#{File.dirname(__FILE__)}/lib"
# テンポラリファイル設置パス
AL_TEMPDIR = "/tmp/"
# 使用キャラクタセット（現在UTF-8固定）
AL_CHARSET = Encoding::UTF_8
# エラーハンドラ
AL_ERROR_HANDLER = "handle_error_display"
#AL_ERROR_HANDLER = "handle_error_static_page"
# 静的コンテンツの設置URI。空文字列ならルートを表す。
#AL_URI_STATIC = "~mine/prog1"
AL_URI_STATIC = ""

#
# Log
#
#  パラメータはLoggger::new メソッドに準ずる。
#  ログを出力したくない場合はコメントアウトする。
AL_LOG_DEV = "/tmp/al_cgi.log"
AL_LOG_AGE = 3
AL_LOG_SIZE = 1048576


#
# Controller
#
# アプリケーションを導入したディレクトリ絶対パス
AL_CTRL_DIR = "#{File.dirname(__FILE__)}/controllers"

#
# Form Manager
#
# 最大リクエストサイズ (bytes)
AL_FORM_MAX_CONTENT_LENGTH = 8000000


#
# Session Manager
#
# セッションをファイルに保存する場合の場所
AL_SESS_DIR = AL_TEMPDIR

# セッションタイムアウト（秒）
AL_SESS_TIMEOUT = 28800


#
# Login Manager
#
# ログインスクリプトのURI
AL_LOGIN_URI = "?ctrl=login"


#
# Template Manager
#
# テンプレート保存場所へのパス。ドットはコントローラと同じディレクトリ。
AL_TEMPLATE_DIR = '.'

# テンプレートキャッシュを使う場合のディレクトリ。nilならキャッシュしない。
AL_TEMPLATE_CACHE = nil
#AL_TEMPLATE_CACHE = "/tmp/alcache"

#  テンプレートセクションで使う、出力するhtmlの断片。
#  TODO: エラーハンドラでも使用した。今後もそうかは要検討。
AL_TEMPLATE_HEADER = %Q(<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <link rel="stylesheet" href="#{AL_URI_STATIC}/al_style.css">\n)
AL_TEMPLATE_BODY = %Q(</head>\n<body>\n)
AL_TEMPLATE_FOOTER = %Q(</body>\n</html>\n)


$LOAD_PATH << AL_BASEDIR
require 'al_main'
