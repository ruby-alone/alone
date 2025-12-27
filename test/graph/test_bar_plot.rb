#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#   Copyright (c) 2010 FAR END Technologies Corporation All Rights Reserved.
#   Copyright (c) 2011 Inas Co Ltd All Rights Reserved.
#   Copyright (c) 2021- Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require_relative "./sub"
require "al_graph"


##
# 棒グラフのテスト
#
class AlGraphBarTest < Test::Unit::TestCase

  ##
  # 棒グラフ
  #
  def test_sample_01
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 3]

    graph = AlGraph.new
    graph.add_data_bar(ydata1, "bar1")
    graph.add_data_bar(ydata2, "bar2")

    svg = graph.draw_buffer
    compare_svg( svg, "bar01.svg" )
  end


  ##
  # 棒グラフ　棒間隔を指定（詰める)
  #
  def test_sample_02
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 3]

    graph = AlGraph.new
    graph.add_data_bar(ydata1, "bar1")
    graph.add_data_bar(ydata2, "bar2")

    graph.bar_plot.spacing = 0

    svg = graph.draw_buffer
    compare_svg( svg, "bar02.svg" )
  end


  ##
  # 棒グラフ　棒間隔を指定（開ける）
  #
  def test_sample_03
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 3]

    graph = AlGraph.new
    graph.add_data_bar(ydata1, "bar1")
    graph.add_data_bar(ydata2, "bar2")

    graph.bar_plot.overlap = -100

    svg = graph.draw_buffer
    compare_svg( svg, "bar03.svg" )
  end


  ##
  # 棒グラフ　色、透明度アレンジ
  #
  def test_sample_04
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 3]

    graph = AlGraph.new
    bar1 = graph.add_data_bar(ydata1, "yellow")
    bar2 = graph.add_data_bar(ydata2, "red")

    bar1.color = 'yellow'
    bar2.color = 'red'
    bar2.at_bar[:opacity] = '0.8'

    graph.bar_plot.overlap = 30
    graph.bar_plot.spacing = 50

    svg = graph.draw_buffer
    compare_svg( svg, "bar04.svg" )
  end


  ##
  # 積み重ね棒グラフ
  #
  def test_sample_05
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 3]
    ydata3 = [8, 1, 8, 5, 7, 3, 6]

    graph = AlGraph.new
    bar1 = graph.add_data_bar(ydata1, "bar1")
    bar2 = graph.add_data_bar(ydata2, "bar2", bar1)
    bar3 = graph.add_data_bar(ydata3, "bar3", bar2)

    svg = graph.draw_buffer
    compare_svg( svg, "bar05.svg" )
  end


  ##
  # 棒グラフと折れ線グラフの重ね合わせ
  #
  def test_sample_06
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 3]

    graph = AlGraph.new
    graph.add_data_line(ydata1, "bar1")
    graph.add_data_bar(ydata2, "bar2")

    svg = graph.draw_buffer
    compare_svg( svg, "bar06.svg" )
  end


  ##
  # 棒グラフ　アレンジ例
  #
  def test_sample_07
    ydata1 = [ 7, 4, 6 ]
    ydata2 = [ 4, 5, 3 ]
    ydata3 = [ 2, 3, 5 ]

    graph = AlGraph.new

    b1 = graph.add_data_bar(ydata1, "Tennis")
    b2 = graph.add_data_bar(ydata2, "Volley", b1)
    b3 = graph.add_data_bar(ydata3, "Soccer", b2)
    b1.at_bar[:opacity] = '0.7'
    b2.at_bar[:opacity] = '0.7'
    b3.at_bar[:opacity] = '0.7'

    graph.bar_plot.spacing = 30

    graph.set_margin(nil, nil, 50, nil)
    graph.at_graph_area[:fill] = '#303030'
    graph.at_plot_area[:fill] = '#303030'
    graph.at_legend[:fill] = '#ffffff'
    graph.at_legend[:y] = 30
    graph.at_legend[:line_spacing] = 20

    graph.x_axis.add_grid
    graph.x_axis.at_scale_line[:stroke] = '#ffffff'
    graph.x_axis.at_interval_marks[:stroke] = '#ffffff'
    graph.x_axis.at_interval_marks[:stroke_dasharray] = '6,3'
    graph.x_axis.at_labels[:fill] = '#ffffff'
    graph.x_axis.set_labels(['Bob', 'Alice', 'Jane'])
    graph.x_axis.at_labels[:rotate] = -40

    graph.y_axis.at_scale_line[:stroke] = '#ffffff'
    graph.y_axis.at_interval_marks[:stroke] = '#ffffff'
    graph.y_axis.at_interval_marks[:stroke_dasharray] = '6,3'
    graph.y_axis.at_labels[:fill] = '#ffffff'
    graph.y_axis.max = 15
    graph.y_axis.min = 0
    graph.y_axis.interval = 5
    graph.y_axis.at_labels[:format] = '%.1f%%'

    graph.add_text(100, 235, '<tspan font-size="10" fill="#ffffff">The power to make your dream come true.</tspan>')

    svg = graph.draw_buffer
    compare_svg( svg, "bar07.svg" )
  end


  ##
  # 棒グラフ　アレンジ例２（バックグラウンドイメージ）
  #
  def test_sample_08
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 3]

    graph = AlGraph.new
    graph.add_data_bar(ydata1, "bar1")
    graph.add_data_bar(ydata2, "bar2")
    graph.at_graph_area[:image] = "/graph/Fabric.jpg"
    graph.at_plot_area[:opacity] = 0.5

    svg = graph.draw_buffer
    compare_svg( svg, "bar08.svg" )
  end


  ##
  #
  # 棒グラフ　与えるデータ個数の不一致とnilを含むデータ
  #
  def test_sample_09
    ydata1 = [2,  5, 4]
    ydata2 = [0,  3]
    ydata3 = [7,nil, 5, 8, 10]
    ydata4 = [1,  2, 1, 2]

    graph = AlGraph.new()
    bar1 = graph.add_data_bar(ydata1, "bar1")
    bar2 = graph.add_data_bar(ydata2, "bar2", bar1)
    bar3 = graph.add_data_bar(ydata3, "bar3", bar2)
    bar4 = graph.add_data_bar(ydata4, "bar4", bar3)

    svg = graph.draw_buffer
    compare_svg( svg, "bar09.svg" )
  end

end
