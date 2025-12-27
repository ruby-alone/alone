#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#   Copyright (c) 2018- Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.

require_relative "./sub"
require "al_graph_scatter"


##
# 散布図のテスト
#
class AlGraphScatterTest < Test::Unit::TestCase

  # 散布図1
  def test_sample_01
    data1 = [ 143.7, 118.1, 135.2, 152.0, 157.8, 153.6, 149.0 ]
    data2 = [  37.5,  22.6,  33.7,  49.1,  53.2,  46.7,  42.7 ]

    graph = AlGraphScatter.new
    graph.add_data( data1, data2 )

    graph.add_main_title("散布図（身長、体重）")
    graph.add_xaxis_title("身長(cm)")
    graph.add_yaxis_title("体重(kg)")
    graph.x_axis.at_labels[:format] = "%d"

    svg = graph.draw_buffer
    compare_svg( svg, "scatter01.svg" )
  end

  # バブルチャート
  def test_sample_02
    group_A_x =    [ 23,  24,  62   ,9]
    group_A_y =    [ -4,   5,  12, -10]
    group_A_size = [ 50,  40,  90,  20]

    group_B_x =    [ 39,  20,   5,  85]
    group_B_y =    [  0,  10, -14,  -6]
    group_B_size = [ 40,  50,  10,  40]
    group_label = ["農林", "製造", "建築土木", "その他"]

    graph = AlGraphScatter.new(800,600)
    graph.color_list = ["#88f", "#f88"]
    graph.shape_list = [:circle, :circle]

    graph.add_xaxis_title("X軸タイトル")
    graph.add_yaxis_title("Y軸タイトル")
    graph.x_axis.at_labels[:format] = "%.0f%%"
    graph.x_axis.min = 0
    graph.x_axis.max = 90
    graph.y_axis.at_labels[:format] = "%.0f%%"
    graph.y_axis.min = -15
    graph.y_axis.max = 25

    data = graph.add_data( group_A_x, group_A_y, "男性" )
    data.add_data_labels(:CENTER)
    data.labels = group_label
    data.at_data_labels[:font_size] = 20
    group_A_size.each_with_index {|sz,i|
      data.at_marker_several[i] = {:size=>sz, :stroke_width=>3,:stroke=>"#fff"}
    }

    data = graph.add_data( group_B_x, group_B_y, "女性" )
    data.add_data_labels(:CENTER)
    data.labels = group_label
    data.at_data_labels[:font_size] = 20
    group_B_size.each_with_index {|sz,i|
      data.at_marker_several[i] = {:size=>sz, :stroke_width=>3,:stroke=>"#fff"}
    }

    svg = graph.draw_buffer
    compare_svg( svg, "scatter02.svg" )
  end

end
