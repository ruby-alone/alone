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
require "al_graph_pie"


##
# 円グラフのテスト
#
class AlGraphPieTest < Test::Unit::TestCase

  ##
  # シンプル
  #
  def test_sample_01
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

    graph = AlGraphPie.new
    graph.add_data(ydata1, labels)

    svg = graph.draw_buffer
    compare_svg( svg, "pie01.svg" )
  end


  ##
  # セパレート
  #
  def test_sample_02
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

    graph = AlGraphPie.new
    ds = graph.add_data(ydata1, labels)
    ds[2].separate

    svg = graph.draw_buffer
    compare_svg( svg, "pie02.svg" )
  end
end
