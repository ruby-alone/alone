# -*- coding: utf-8 -*-
# alone : application framework for embedded systems.
#          Copyright (c) 2018-2021 Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# 散布図クラスを定義
#
# (GraphView) --- (GraphBase) - (Graph) - (GraphXY) - GraphScatter
#

require "al_graph_xy"


##
# 散布図モジュール
#
module AlGraphScatter

  ##
  #  散布図用クラス
  #
  class GraphScatter < AlGraphXY::GraphXY

    ##
    # (GraphXY)
    # データ追加
    #
    #@param [Array<Numeric>] data1      データの配列 X軸
    #@param [Array<Numeric>] data2      データの配列 Y軸
    #@param [String] legend             データの名前（凡例）
    #@return [ContainerXY]              データコンテナオブジェクト
    #
    def add_data(data1, data2, legend = nil)
      obj = super
      obj.clear_line()
      return obj
    end

  end  # /GraphScatter



  ##
  # AlGraphScatter::GraphScatterのインスタンス生成
  #
  def self.new(*params)
    AlGraphScatter::GraphScatter.new(*params)
  end

end  # /AlGraphScatter
