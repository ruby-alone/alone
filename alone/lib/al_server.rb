#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# alone : application framework for small embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2022 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the COPYRIGHT file.
#
# 簡易httpサーバ
#
#@note
# これはライブラリではなく、webrickを利用した独立して動作するhttpサーバである。
#  Usage: ruby al_server.rb [document root path] [port number]
#

require 'webrick'

#
# バージョンチェック
#
if RUBY_VERSION < '2.0'
  puts "Ruby version error. needs 2.0 or later."
  exit
end

#
# ドキュメントルートディレクトリ、ポート番号の決定
#
document_root = File.absolute_path( File.join( File.dirname(__FILE__), "..", "htdocs" ))
port_no = 3000
if ARGV[0].to_i != 0
  port_no = ARGV[0].to_i

elsif ARGV[0]
  document_root = ARGV[0]

  if ARGV[1].to_i != 0
    port_no = ARGV[1].to_i
  end
end

puts "DocumentRoot: #{document_root}"
puts "PortNo: #{port_no}"

#
# WEBrickサーバ用CGIハンドラの定義。*.rbファイルをCGIプログラムとする。
#
module WEBrick::HTTPServlet
  FileHandler.add_handler("rb", CGIHandler)
end

#
# サーバインスタンスの生成
#
httpd = WEBrick::HTTPServer.new(
        :DocumentRoot => document_root,
        :Port => port_no,
        :DirectoryIndex => [ "index.html", "index.htm", "index.rb" ],
        :CGIInterpreter => WEBrick::HTTPServlet::CGIHandler::Ruby,
)

#
# 終了シグナルを補足したら、shutdownで終了させるためのハンドラを登録する。
#
Signal.trap( 'INT' ) { httpd.shutdown() }
Signal.trap( 'TERM' ) { httpd.shutdown() }

#
# サーバスタート
#
httpd.start()
