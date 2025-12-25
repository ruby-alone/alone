#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# 設定情報保存ファイル
# 必要に応じて書き換えること。
#
# 標準のディレクトリ構造
#  /PATH/TO/ --- al_config.rb  -- 共通設定ファイル（このファイル）
#             +- lib/          -- Aloneライブラリ
#             +- controllers/  -- コントローラ
#             +- views/        -- htmlテンプレート
#             +- models/       -- モデル
#             +- htdocs/       -- ドキュメントルート、スタティックコンテンツ
#             +- bin/          -- 常駐プログラム(AlWorker)等


# ディレクトリ設定
AL_BASE_DIR  = File.dirname(__FILE__)
AL_LIB_DIR   = "#{AL_BASE_DIR}/lib"
AL_CTRL_DIR  = "#{AL_BASE_DIR}/controllers"
AL_MODEL_DIR = "#{AL_BASE_DIR}/models"
AL_BASEDIR = AL_LIB_DIR                 # for backward compatibility.

# テンポラリファイル設置パス
AL_TEMP_DIR = "/tmp/"
AL_TEMPDIR = AL_TEMP_DIR                # for backward compatibility.

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
# Form Manager
#
# 最大リクエストサイズ (bytes)
AL_FORM_MAX_CONTENT_LENGTH = 8000000


#
# Session Manager
#
# セッションをファイルに保存する場合の場所
AL_SESS_DIR = AL_TEMP_DIR

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
#AL_TEMPLATE_DIR = '.'
AL_TEMPLATE_DIR = "#{AL_BASE_DIR}/views"

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

#
# Default locale
#
AL_DEFAULT_LOCALE="ja_JP"


$LOAD_PATH << AL_LIB_DIR << AL_MODEL_DIR
