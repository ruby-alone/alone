#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#   Copyright (c) 2010 FAR END Technologies Corporation All Rights Reserved.
#   Copyright (c) 2011 Inas Co Ltd All Rights Reserved.
#   Copyright (c) 2025- Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require_relative "./sub"
require "al_graph"


##
# 折れ線グラフのテスト
#
class AlGraphLineTest < Test::Unit::TestCase

  ##
  # 折れ線グラフ
  #
  def test_sample_01
    ydata1 = [ 5, 3, 6, 3, 2, 5, 6 ]

    graph = AlGraph.new
    graph.add_data_line(ydata1)

    svg = graph.draw_buffer
    compare_svg( svg, "line01.svg" )
  end


  ##
  # 折れ線２本 with X軸ラベル
  #
  def test_sample_02
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 13]

    graph = AlGraph.new
    graph.add_data_line(ydata1)
    graph.add_data_line(ydata2)

    graph.x_axis.set_labels(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']);

    svg = graph.draw_buffer
    compare_svg( svg, "line02.svg" )
  end


  ##
  # ラベル類の付与
  #
  def test_sample_03
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 13]

    graph = AlGraph.new
    graph.x_axis.change_mode(:CENTER)

    l1 = graph.add_data_line(ydata1, "Bob")
    l2 = graph.add_data_line(ydata2, "Alice")

    l1.add_data_labels
    l2.add_data_labels

    graph.x_axis.set_labels(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'])
    graph.add_main_title("Main title")
    graph.add_xaxis_title("X-Axis title")
    graph.add_yaxis_title("Y-Axis title")

    svg = graph.draw_buffer
    compare_svg( svg, "line03.svg" )
  end


  ##
  # グリッド線のコントロール
  #
  def test_sample_04
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 13]

    graph = AlGraph.new

    graph.add_data_line(ydata1)
    graph.add_data_line(ydata2)

    graph.x_axis.clear_labels
    graph.x_axis.add_grid
    graph.x_axis.at_interval_marks[:stroke] = '#ff0fc0'
    graph.x_axis.at_interval_marks[:stroke_width] = 3
    graph.x_axis.at_interval_marks[:stroke_dasharray] = "6,3"

    graph.y_axis.clear_grid
    graph.y_axis.at_interval_marks[:length] = -5
    graph.y_axis.clear_scale_line

    svg = graph.draw_buffer
    compare_svg( svg, "line04.svg" )
  end


  ##
  # 第２Y軸の追加
  #
  def test_sample_05
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [22.5, 24.8, 26.1, 25.3, 24, 23.5, 20.6]

    graph = AlGraph.new

    graph.add_data_line(ydata1, "on Y1")
    graph.add_data_line_y2(ydata2, "on Y2")
    graph.y_axis.clear_grid

    svg = graph.draw_buffer
    compare_svg( svg, "line05.svg" )
  end


  ##
  # スケール（軸）を指定（最大、最小、インターバル、上下反転）
  #
  def test_sample_06
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 13]

    graph = AlGraph.new

    graph.add_data_line(ydata1)
    graph.add_data_line(ydata2)

    graph.y_axis.max = 20
    graph.y_axis.min = -5
    graph.y_axis.interval = 5
    graph.y_axis.reverse

    svg = graph.draw_buffer
    compare_svg( svg, "line06.svg" )
  end


  ##
  # プロット線とマーカーを指定
  #
  def test_sample_07
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 13]

    graph = AlGraph.new

    line1 = graph.add_data_line(ydata1, 'MarkerOnly')
    line1.color = 'yellow'
    line1.at_marker[:shape] = 'triangle'
    line1.clear_line

    line2 = graph.add_data_line(ydata2, 'LineOnly')
    line2.clear_marker

    svg = graph.draw_buffer
    compare_svg( svg, "line07.svg" )
  end
end
