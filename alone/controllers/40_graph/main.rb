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
# グラフ描画ライブラリAlGraphサンプル
#

require "al_template"
require "al_form"
require "./line_plot"
require "./bar_plot"
require "./pie_chart"
require "./xy_plot"
require "./log_plot"
require "./scatter_plot"

class AlControllerGraph < AlController
  #
  # デフォルトアクション
  #
  def action_index()
    AlTemplate.run("index.rhtml")
  end

  #
  # 折れ線グラフサンプル
  #
  def action_line_plot()
    extract_actions("line_plot.rb")
    AlTemplate.run("line_plot.rhtml")
  end

  #
  # 棒グラフサンプル
  #
  def action_bar_plot
    extract_actions("bar_plot.rb")
    AlTemplate.run("bar_plot.rhtml")
  end

  #
  # 円グラフサンプル
  #
  def action_pie_chart
    extract_actions("pie_chart.rb")
    AlTemplate.run("pie_chart.rhtml")
  end

  #
  # XYグラフサンプル
  #
  def action_xy_plot
    extract_actions("xy_plot.rb")
    AlTemplate.run("xy_plot.rhtml")
  end

  #
  # 対数グラフサンプル
  #
  def action_log_plot
    extract_actions("log_plot.rb")
    AlTemplate.run("log_plot.rhtml")
  end

  #
  # 散布図サンプル
  #
  def action_scatter_plot
    extract_actions("scatter_plot.rb")
    AlTemplate.run("scatter_plot.rhtml")
  end

  #
  # ソース表示用にアクションを抽出する
  #
  def extract_actions(filename)
    action_name = nil
    contents = ""

    # インデントと識別子を頼りに、ごく簡単にソースコードを抜き出す
    File.read( filename ).each_line {|line|
      if /^  def action_(\w+)/ =~ line
        action_name = $1
        contents = line
      elsif !action_name
        next
      elsif /^  end/ =~ line
        contents << line
        instance_variable_set("@src_#{action_name}", contents)
        action_name = nil
      else
        contents << line
      end
    }
  end

end
