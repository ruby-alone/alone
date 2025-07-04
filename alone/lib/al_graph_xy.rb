# -*- coding: utf-8 -*-
# alone : application framework for small embedded systems.
#          Copyright (c) 2021 Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the COPYRIGHT file.
#
# XYグラフクラスを定義
#
# (GraphView) --- (GraphBase) - (Graph) - GraphXY
#               - (Axis) -- (XAxis) -- XAxisReal
#
# (DataContainer) - (ContainerLine) - ContainerXY
#

require "al_graph"

##
# XYグラフモジュール
#
module AlGraphXY

  ##
  # XYグラフ用クラス
  #
  class GraphXY < AlGraph::Graph

    ##
    # (GraphXY)
    # constructor
    #
    #@param [Integer] width      幅
    #@param [Integer] height     高さ
    #
    def initialize(width = 320, height = 240)
      super

      @x_axis = XAxisReal.new(@at_plot_area[:width], @at_plot_area[:height])
    end

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
      add_legend() if legend
      @line_plot = AlGraph::LinePlot.new(@width, @height) if ! @line_plot

      data_obj = ContainerXY.new(data1, data2, legend)
      data_obj.x_axis = @x_axis
      data_obj.y_axis = @y_axis
      data_obj.plot = @line_plot
      data_obj.at_marker[:shape] = @shape_list[ @data_series.size % @shape_list.size ]
      data_obj.at_marker[:fill] = @color_list[ @data_series.size % @color_list.size ]
      data_obj.at_plot_line[:stroke] = data_obj.at_marker[:fill]

      add_data_series(data_obj)
      @line_plot.add_data_series(data_obj)
      @x_axis.add_data_series(data_obj)
      @y_axis.add_data_series(data_obj)

      return data_obj
    end

    ##
    # (GraphXY)
    # データペア追加
    #
    # \[[x1,y1],...] もしくは [x1,y1,x2,y2...] の型式でデータを与える
    #
    #@param [Array<Array<Numeric,Numeric>>, Array<Numeric>] data データの配列
    #@param [String] legend             データの名前（凡例）
    #@return [ContainerXY]              データコンテナオブジェクト
    #
    def add_data_pair(data, legend = nil)
      data1 = []
      data2 = []
      data.flatten.each_slice(2) {|d1, d2|
        data1 << d1
        data2 << d2
      }

      return add_data(data1, data2, legend)
    end

  end  # /GraphXY



  ##
  # XYグラフ及び散布図用 X軸クラス
  #
  class XAxisReal < AlGraph::XAxis

    ##
    # (XAxisReal)
    # constructor
    #
    #@param [Integer] width     幅
    #@param [Integer] height    高さ
    #
    def initialize(width, height)
      super

      @scale_mode = :LINER
      @at_interval_marks[:grid] = true
    end

    ##
    # (XAxisReal)
    # 目盛りスケーリング
    #
    #@return [Boolean]     成功時、真
    #
    #  あらかじめ与えられているデータ系列情報などを元に、
    #  オートスケール処理など、内部データの整合性をとる。
    #
    def do_scaling()
      case @scale_mode
      when :LINER
        do_scaling_liner(:@x_data)
      when :LOGARITHMIC
        do_scaling_logarithmic(:@x_data)
      else
        raise "Not support #{@scale_mode} mode."
      end
    end

    ##
    # (XAxisReal)
    # 軸上のピクセル位置を計算する。
    #
    #@param [Numeric] v    実数
    #@return [Integer]     ピクセル位置
    #
    #  引数が軸上にない場合、返り値も軸上にはないピクセル位置が返る。
    #
    def calc_pixcel_position(v)
      case @scale_mode
      when :LINER
        x = (@width * (v - @scale_min) / @scale_max_min).to_i
      when :LOGARITHMIC
        x = (@width * Math.log10(v/@scale_min) / @scale_max_min).to_i
      else
        raise "Not support #{@scale_mode} mode."
      end
      return @flag_reverse ? @width - x : x
    end

    ##
    # (XAxisReal)
    # 描画　1st pass
    #
    #  スケール描画　パス１。
    #
    #@param [Object] output     出力先
    #@visibility private
    def draw_z1( output )
      return if @at_interval_marks.empty?

      #
      # draw interval marks or grid lines
      #
      output.printf("\n<!-- draw X-axis pass 1 -->\n")
      if @at_interval_marks[:length] < 0
        y1 = @height - @at_interval_marks[:length]
        y2 = @height
      else
        y1 = @height
        y2 = @height - @at_interval_marks[:length]
      end
      if @at_interval_marks[:grid]
        y2 = 0
      end

      draw_z1_sub(output, %!  <line x1="%d" y1="#{y1}" x2="%d" y2="#{y2}" />\n!)
    end

    ##
    # (XAxisReal)
    # 描画　2nd pass
    #
    #  スケール描画　パス２　X軸横線、ラベル（数値）の描画
    #
    #@param [Object] output     出力先
    #@visibility private
    def draw_z2( output )
      output.printf("\n<!-- draw X-axis pass 2 -->\n")

      # draw scale line
      if !@at_scale_line.empty?
        output.printf(%!<line x1="%d" y1="%d" x2="%d" y2="%d" %s />\n!,
                      0, @height, @width, @height,
                      make_common_attribute_string(@at_scale_line))
      end

      # draw labels
      if !@at_labels.empty?
        adjust_text_anchor()
        draw_labels( output ) {|v|
          {:x=>calc_pixcel_position(v),
           :y=>@height + @at_labels[:font_size] + 5,
           :v=>v}
        }
      end
    end

  end  # /XAxisReal



  ##
  # XYグラフ及び散布図用 データコンテナ
  #
  class ContainerXY < AlGraph::ContainerLine

    #@return [Array<Numeric>] X値データ
    attr_accessor :x_data


    ##
    # (ContainerXY)
    # constructor
    #
    #@param [Array<Numeric>] xdata   X値データ
    #@param [Array<Numeric>] ydata   Y値データ
    #@param [String] legend          凡例文字列
    #
    def initialize(xdata, ydata, legend = nil)
      super(ydata, legend)

      @x_data = xdata
    end

    ##
    # イテレータ
    #
    def each()
      @x_data.each_with_index {|xd, i|
        yield( xd, @y_data[i], i )
      }
    end

  end  # /ContainerXY



  ##
  # AlGraphXY::GraphXYのインスタンス生成
  #
  def self.new(*params)
    AlGraphXY::GraphXY.new(*params)
  end

end  # /AlGraphXY
