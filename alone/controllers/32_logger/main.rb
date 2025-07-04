#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# alone : application framework for small embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2022 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the COPYRIGHT file.
#

require "alone"

class ViewLogController < AlController

  #
  # デフォルトアクション
  #
  def action_index()
    AlTemplate.run( 'index.rhtml' )
  end


  #
  # ログ表示
  #
  def action_view_log()
    Alone::add_http_header("Content-Type: text/plain; charset=UTF-8")

    File.open(AL_LOG_DEV) {|file|
      while text = file.gets
        puts text
      end
    }

  rescue Errno::ENOENT
    puts "File not found."
  end


  #
  # ログの追記
  #
  def action_append_log()
    text = AlForm.get_parameter( AlText.new("text") )
    Alone.log( text )
  end


end
