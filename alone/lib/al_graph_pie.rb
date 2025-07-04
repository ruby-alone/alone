# -*- coding: utf-8 -*-
# alone : application framework for small embedded systems.
#               Copyright (c) 2010-2017
#                 Inas Co Ltd., FAR END Technologies Corporation,
#                 All Rights Reserved.
#
# This file is destributed under BSD License. Please read the COPYRIGHT file.
#
# 円グラフに関するクラスを定義
#
# (GraphView) - (GraphBase) - GraphPie
#
# ContainerPie
#

require 'al_graph_base'


module AlGraphPie

  class GraphPie < AlGraph::GraphBase

    #@return [Hash] データラベルアトリビュート（未実装）
    attr_accessor :at_data_labels

    ##
    # (GraphPie)
    # constructor
    #
    #@param [Integer] width     幅
    #@param [Integer] height    高さ
    #@param [String]  id        ID
    #
    def initialize(width = 320, height = 240, id = nil)
      super

      @at_plot_area = {:x=>10, :y=>10, :fill=>'#fff'}
      @at_data_labels = nil

      #
      # make default
      #
      @at_plot_area[:width] = @width - 20
      @at_plot_area[:width] = 0 if @at_plot_area[:width] < 0
      @at_plot_area[:height] = @height - 20
      @at_plot_area[:height] = 0 if @at_plot_area[:height] < 0
    end

    ##
    # (GraphPie)
    # データの追加
    #
    #@param [Array<Numeric>] ydata   データの配列
    #@param [Array<String>] labels   ラベルの配列
    #
    def add_data(ydata, labels = [])
      ydata.each_with_index {|yd, i|
        color = @color_list[i % @color_list.size]
        @data_series << ContainerPie.new(yd, labels[i], color)
      }
      add_legend() if !labels.empty?

      return @data_series
    end

    ##
    # (GraphPie)
    # 描画
    #
    #@visibility private
    def draw()
      #
      # calc some params.
      #
      total = 0.0
      @data_series.each {|ds|
        total += ds.data_value
      }

      @data_series.each {|ds|
        ds.percentage = ds.data_value / total
      }

      cx0 = @at_plot_area[:x] + @at_plot_area[:width] / 2
      cy0 = @at_plot_area[:y] + @at_plot_area[:height] / 2
      if @at_plot_area[:r]
        r = @at_plot_area[:r]
      else
        r = (@at_plot_area[:width] < @at_plot_area[:height]) ? @at_plot_area[:width] : @at_plot_area[:height]
        r = r / 2 - 10
        r = 0 if r < 0
      end

      #
      #  draw start.
      #
      draw_common1()

      #
      # draw each pieces.
      #
      @output.printf("\n<!-- draw pie chart -->\n")

      x1 = 0.0
      y1 = -r.to_f
      total2 = 0.0
      @data_series.each_with_index {|ds, i|
        vector = (total2 + ds.data_value / 2.0 ) / total * 2 * Math::PI
        total2 += ds.data_value
        x2 =  r * Math::sin(total2 / total * 2 * Math::PI)
        y2 = -r * Math::cos(total2 / total * 2 * Math::PI)
        l_arc = (ds.percentage > 0.5) ? 1 : 0

        if (x1 - x2).abs < 0.1 && (y1 - y2).abs < 0.1
          if l_arc == 1
            # 1個のデータのみで100%を占める場合はcircle要素で描画。
            # path要素を使うとarctoの始点・終点が同じ座標になるため期待通り
            # の描画ができない。
            @output.printf(%Q|<circle cx="%d" cy="%d" r="%d" %s />\n|,
              cx0, cy0, r, make_common_attribute_string(ds.at_piece))
          else
            # 0%の要素は何も描画しない。
          end
        else
          if(ds.at_piece[:separate_distance])
            d = ds.at_piece[:separate_distance]
            cx = cx0 + d * Math::sin(vector)
            cy = cy0 - d * Math::cos(vector)
          else
            cx = cx0
            cy = cy0
          end
          @output.printf(%Q|<path d="M0,0 L%f,%f A%d,%d 0 %d,1 %f,%f Z" transform="translate(%d,%d)" %s />\n|,
            x1,y1, r,r, l_arc, x2,y2, cx,cy,
            make_common_attribute_string(ds.at_piece))
        end
        x1 = x2
        y1 = y2
      }

      #
      # draw legend
      #
      if @at_legend
        @output.printf( "\n<!-- draw legends -->\n" )
        if ! @at_legend[:y]
          @at_legend[:y] = (@height - @data_series.size * (@at_legend[:font_size] + @at_legend[:line_spacing])) / 2
          @at_legend[:y] = 0 if @at_legend[:y] < 0
        end

        attr = @at_legend.dup
        attr[:x] += 10
        attr[:y] += attr[:font_size]

        @data_series.each {|ds|
          if ds.id
            @output.printf(%!<g id="legend-%s">\n!, ds.id)
          else
            @output.printf("<g>\n")
          end
          @output.printf("  <text %s>%s</text>\n  ", make_common_attribute_string(attr), Alone::escape_html(ds.legend))
          @output.printf(%!<rect x="%d" y="%d" width="%d" height="%d" stroke="black" stroke-width="1" fill="%s" />\n!,
            attr[:x] - attr[:font_size] - 5,
            attr[:y] - attr[:font_size],
            attr[:font_size], attr[:font_size],
            ds.at_piece[:fill])
          attr[:y] += attr[:font_size] + attr[:line_spacing]
          @output.printf("</g>\n")
        }
        @output.printf("\n")
      end

      draw_common2()
    end

    ##
    # (GraphPie)
    # 値ラベルを表示
    #@todo 未実装
    #
    def add_data_labels()
      @at_data_labels = {:font_size=>9}
    end

  end  #/GraphPie


  ##
  # 円グラフ用データコンテナ
  #
  class ContainerPie

    #@return [String] ID
    attr_accessor :id

    #@return [Numeric] データ値
    attr_accessor :data_value

    #@return [Float] 全体率
    attr_accessor :percentage

    #@return [String] 凡例文字列
    attr_accessor :legend

    #@return [Hash] グラフアトリビュート
    attr_accessor :at_piece


    ##
    # (ContainerPie)
    # constructor
    #
    #@param [Numeric] value  データ値
    #@param [String] legend  凡例文字列
    #@param [String] color   色(HTMLカラーコード)
    #@note
    #  データ列を管理するのではなく、一つの値を管理する。
    #  折れ線用(ContainerLine)などとは思想が違うので注意。
    #
    def initialize(value, legend, color)
      @at_piece = {:stroke_width=>1, :stroke=>'black'}

      @data_value = value
      @legend = legend
      @at_piece[:fill] = color
    end

    ##
    # (ContainerPie)
    # 色の指定
    #
    #@param [String] color   色(HTMLカラーコード)
    #
    def set_color(color)
      @at_piece[:fill] = color
    end

    ##
    # (ContainerPie)
    # セパレート
    #
    #@param [Integer] dim  距離
    #
    def separate(dim = 20)
      @at_piece[:separate_distance] = dim
    end

  end  # /ContainerPie


  ##
  # AlGraphPie::GraphPieのインスタンス生成
  #
  # AlGraphPie::GraphPieのインスタンスを生成して返す。
  # AlGraphPie::GraphPie.newのかわりにAlGraphPie.newと書くことができる。
  #
  def self.new(*params)
    AlGraphPie::GraphPie.new(*params)
  end

end  # /AlGraphPie
