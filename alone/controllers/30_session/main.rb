#!/usr/bin/env ruby
# alone : application framework for embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2025 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require 'alone'

class SessionTestController < AlController

  #
  # デフォルトアクション
  #
  def action_index()
    # グローバルなセッション変数
    @now = Time.now

    # コントローラローカルセッション
    # （コントローラごとに名前空間が違う）
    @reload_count = session[:reload_count] || 0
    session[:reload_count] = @reload_count + 1

    AlTemplate.run("./index.rhtml")
    AlSession[:visit_before] = @now
  end
end
