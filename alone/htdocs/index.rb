#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# エントリーポイント
#
# 導入する環境にあわせて、shebang（一行目）とal_configのパスを書換える。
# CGIそのものが動作しているか確認するには、以下の行を有功にし、ブラウザ
# 画面に It works! と表示されるかを確認する。
#  puts "Content-Type: text/plain\r\n\r\nIt works!"; exit

require_relative '../al_config'
require 'al_gettext'; include AlGetText         # see: alone_gettext.md
require 'al_controller'
