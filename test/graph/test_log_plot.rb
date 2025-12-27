#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#   Copyright (c) 2021- Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require_relative "./sub"
require "al_graph_xy"


##
# 対数グラフのテスト
#
class AlGraphLogTest < Test::Unit::TestCase

  ##
  # 片対数グラフ 基本
  #
  def test_sample_01
    ydata1 = [ 0.1, 1, 10, 100 ]

    graph = AlGraph.new
    graph.y_axis.logarithmic()
    graph.add_data_line(ydata1)

    svg = graph.draw_buffer
    compare_svg( svg, "log01.svg" )
  end

  ##
  # 片対数グラフ 軸目盛の指定 異常値の自動排除
  #
  def test_sample_02
    ydata1 = [ 0.1, 1, 10, 100, 1000, nil ]
    ydata2 = [ 0.2, 2, 20, 0, -1, 200 ]

    graph = AlGraph.new
    graph.y_axis.logarithmic()
    graph.y_axis.interval = [1,2,5]
    graph.add_data_line(ydata1, "正常値のみ")
    graph.add_data_line(ydata2, "異常値含む")

    svg = graph.draw_buffer
    compare_svg( svg, "log02.svg" )
  end

  ##
  # 片対数グラフ Y2軸を対数にする
  #
  def test_sample_03
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    ydata2 = [0, 1, 4, 10, 9, 13, 13]

    graph = AlGraph.new
    graph.add_data_line( ydata1 )
    graph.add_data_line_y2( ydata2 )
    graph.y2_axis.logarithmic()

    svg = graph.draw_buffer
    compare_svg( svg, "log03.svg" )
  end

  ##
  # 両対数グラフ
  #
  def test_sample_04
    xdata1 = [ 0.1, 1, 10, 100 ]
    ydata1 = [ 0.1, 1, 10, 100 ]

    graph = AlGraphXY.new
    graph.x_axis.logarithmic()
    graph.y_axis.logarithmic()
    graph.add_data( xdata1, ydata1 )

    svg = graph.draw_buffer
    compare_svg( svg, "log04.svg" )
  end

  ##
  # 両対数グラフ 積層セラミックコンデンサ周波数特性
  #
  def test_sample_05
    freq = [ 100,   1e3, 10e3, 100e3,   1e6,   3e6,  10e6, 15e6,   22e6,   30e6,  40e6,  50e6,  60e6, 80e6, 100e6, 400e6,  1e9,  2e9, 4e9, 6e9 ]
    imp  = [18e3, 1.8e3,  180,    18,   1.8,  0.56,  0.15, 0.06,  0.018,   0.04, 0.085, 0.085,  0.13, 0.16,   0.2,   0.7,  1.9,  3.8, 8.0,  12 ]
    esr  = [  70,     7,  0.7,  0.12, 0.023, 0.014, 0.015, 0.016, 0.018,  0.022,  0.05,  0.04,  0.05, 0.07,  0.06,   0.1, 0.13, 0.25, 0.7, 3.5 ]

    graph = AlGraphXY.new( 500, 400 )
    graph.add_xaxis_title("Frequency (Hz)")
    graph.add_yaxis_title("Impedance/ESR (Ω)")

    graph.x_axis.logarithmic()
    graph.y_axis.logarithmic()

    graph.x_axis.at_labels[:renderer] = lambda {|v| to_eng(v)}
    graph.y_axis.at_labels[:renderer] = lambda {|v| to_eng(v)}

    line1 = graph.add_data( freq, imp, "Impedance" )
    line2 = graph.add_data( freq, esr, "ESR" )
    line1.clear_marker
    line2.clear_marker

    svg = graph.draw_buffer
    compare_svg( svg, "log05.svg" )
  end

  def to_eng( v )
    n = Math.log10(v).floor / 3
    sprintf("%.0f%s", (v / 10**(n*3)), "yzafpnμm kMGTPEZY"[ n-9 ].strip)
  end
end
