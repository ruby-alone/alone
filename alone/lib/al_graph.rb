# -*- coding: utf-8 -*-
# alone : application framework for embedded systems.
#          Copyright (c) 2010-2017
#                 Inas Co Ltd., FAR END Technologies Corporation,
#                 All Rights Reserved.
#          Copyright (c) 2021 Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# 折れ線グラフと棒グラフに関するクラスを定義
#
# (GraphView) --- (GraphBase) - Graph
#               - Axis -- XAxis
#                      -- YAxis - Y2Axis
#               - LinePlot
#               - BarPlot
#
# DataContainer - ContainerLine
#               - ContainerBar
#

require 'al_graph_base'

module AlGraph

  ##
  #  折れ線と棒グラフ用クラス
  #
  class Graph < GraphBase

    # マーカ形状リスト初期値
    SHAPE_LIST = [:circle, :rectangle, :diamond, :triangle, :cock]

    #@return [Array<Symbol>] マーカ形状リスト
    attr_accessor :shape_list

    #@return [Hash]  Ｘ軸タイトルアトリビュート
    attr_accessor :at_xaxis_title

    #@return [Hash]  Ｘ軸単位表示アトリビュート
    attr_accessor :at_xaxis_unit

    #@return [Hash]  Ｙ軸タイトルアトリビュート
    attr_accessor :at_yaxis_title

    #@return [Hash]  Ｙ軸単位表示アトリビュート
    attr_accessor :at_yaxis_unit

    #@return [Hash]  Ｙ２軸単位表示アトリビュート
    attr_accessor :at_y2axis_unit

    #@return [XAxis]  Ｘ軸オブジェクト
    attr_accessor :x_axis

    #@return [YAxis]  Ｙ軸オブジェクト
    attr_accessor :y_axis

    #@return [Y2Axis]  Ｙ２軸オブジェクト（もしあれば）
    attr_accessor :y2_axis

    #@return [LinePlot]  折れ線グラフオブジェクト
    attr_accessor :line_plot

    #@return [BarPlot]  棒グラフオブジェクト
    attr_accessor :bar_plot

    ##
    # (Graph)
    # constructor
    #
    #@param [Integer] width     幅
    #@param [Integer] height    高さ
    #@param [String]  id        ID
    #
    def initialize(width = 320, height = 240, id = nil)
      super

      @shape_list = SHAPE_LIST
      @at_plot_area = {:x=>40, :y=>10, :fill=>'#eee'}

      # make default
      @at_plot_area[:width] = @width - 50
      @at_plot_area[:width] = 0 if @at_plot_area[:width] < 0
      @at_plot_area[:height] = @height - 30
      @at_plot_area[:Height] = 0 if @at_plot_area[:height] < 0
      @x_axis = XAxis.new(@at_plot_area[:width], @at_plot_area[:height])
      @y_axis = YAxis.new(@at_plot_area[:width], @at_plot_area[:height])
    end

    ##
    # (Graph)
    # 折れ線の追加
    #
    #@param [Array<Numeric>] ydata   データの配列
    #@param [String] legend          データの名前（凡例）
    #@return [ContainerLine]         データコンテナオブジェクト
    #
    def add_data_line(ydata, legend = nil)
      add_legend() if legend
      @line_plot = LinePlot.new(@width, @height) if ! @line_plot

      data_obj = ContainerLine.new(ydata, legend)
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
    # (Graph)
    # 第２Ｙ軸上へ折れ線の追加
    #
    #@param [Array<Numeric>] ydata   データの配列
    #@param [String] legend          データの名前（凡例）
    #@return [ContainerLine]         データコンテナオブジェクト
    #
    def add_data_line_y2(ydata, legend = nil)
      add_legend() if legend
      if ! @y2_axis
        @y2_axis =
          Y2Axis.new(@at_plot_area[:width], @at_plot_area[:height])
        right = @width - @at_plot_area[:width] - @at_plot_area[:x] + 20
        set_margin(nil, right, nil, nil)
      end

      @line_plot = LinePlot.new(@width, @height) if ! @line_plot

      data_obj = ContainerLine.new(ydata, legend)
      data_obj.x_axis = @x_axis
      data_obj.y_axis = @y2_axis
      data_obj.plot = @line_plot
      data_obj.at_marker[:shape] = @shape_list[ @data_series.size % @shape_list.size ]
      data_obj.at_marker[:fill] = @color_list[ @data_series.size % @color_list.size ]
      data_obj.at_plot_line[:stroke] = data_obj.at_marker[:fill]

      add_data_series(data_obj)
      @line_plot.add_data_series(data_obj)
      @x_axis.add_data_series(data_obj)
      @y2_axis.add_data_series(data_obj)

      return data_obj
    end

    ##
    # (Graph)
    # 棒グラフの追加
    #
    #@param [Array<Numeric>] ydata   データの配列
    #@param [String] legend          データの名前（凡例）
    #@param [ContainerBar]           base_bar 積み重ねする場合、ベースになるデータコンテナ
    #@return [ContainerBar]          データコンテナオブジェクト
    #
    def add_data_bar(ydata, legend = nil, base_bar = nil)
      #
      # 積み重ねの場合、Y値を調整。
      #
      if base_bar
        diffsize = base_bar.y_data.size - ydata.size
        ydata.concat( Array.new(diffsize, 0) )  if diffsize > 0

        ydata.each_with_index {|yd, i|
          ydata[i] = 0  if !ydata[i]
          ydata[i] += base_bar.y_data[i]  if base_bar.y_data[i]
        }
      end

      add_legend() if legend

      @bar_plot = BarPlot.new(@width, @height) if ! @bar_plot
      @x_axis.change_mode(:CENTER)

      #
      # コンテナオブジェクトの生成
      #
      data_obj = ContainerBar.new(ydata, legend)
      data_obj.x_axis = @x_axis
      data_obj.y_axis = @y_axis
      data_obj.plot = @bar_plot
      data_obj.at_bar[:fill] = @color_list[ @data_series.size % @color_list.size ]

      #
      # コンテナを配列に保存
      #
      if base_bar
        data_obj.set_stack( base_bar )
        @data_series.each_with_index {|ds, i|
          if ds == base_bar
            @data_series.insert(i, data_obj)
            break
          end
        }
      else
        @data_series << data_obj
      end

      @bar_plot.add_data_series(data_obj, base_bar)
      @x_axis.add_data_series(data_obj)
      @y_axis.add_data_series(data_obj)

      return data_obj
    end

    ##
    # (Graph)
    # 描画
    #
    # 管理下のオブジェクトを次々とcallして、全体を描画する。
    # （ユーザが個々の内部オブジェクトのdrawメソッドを使うことは無い）
    #
    #@raise [AutoScaleErrorX]  X軸でオートスケールができなかった時
    #@raise [AutoScaleErrorY]  Y軸でオートスケールができなかった時
    #@raise [AutoScaleErrorY2] Y2軸でオートスケールができなかった時
    #
    def draw()
      #
      # scaling.
      #
      if !@x_axis.do_scaling
        raise AutoScaleErrorX
      end
      if !@y_axis.do_scaling
        raise AutoScaleErrorY
      end
      if @y2_axis && !@y2_axis.do_scaling
        raise AutoScaleErrorY2
      end

      #
      # draw base items.
      #
      draw_common1()

      #
      # output plot area's clipping path.
      #
      clippath_id = "plotarea-#{@id}-#{rand(2147483648)}"
      @output.printf(%!<clipPath id="#{clippath_id}">\n!)
      @output.printf(%!  <rect x="%d" y="%d" width="%d" height="%d" />\n!, -5, -5, @at_plot_area[:width] + 10, @at_plot_area[:height] + 10)
      @output.printf("</clipPath>\n")

      #
      # grouping in plot items.
      #
      @output.printf(%!<g transform="translate(%d,%d)">\n!, @at_plot_area[:x], @at_plot_area[:y])

      #
      # draw X,Y axis
      #
      @x_axis.draw_z1(@output)
      @y_axis.draw_z1(@output)
      @y2_axis.draw_z1(@output) if @y2_axis

      @x_axis.draw_z2(@output)
      @y_axis.draw_z2(@output)
      @y2_axis.draw_z2(@output) if @y2_axis

      #
      # draw data series.
      #
      @output.printf("\n<!-- draw lines and bars in clipping path -->\n")
      @output.printf(%!<g clip-path="url(##{clippath_id})">\n!)

      @bar_plot.draw(@output) if @bar_plot
      @line_plot.draw(@output) if @line_plot

      @output.printf("</g><!-- end of clip -->\n")

      #
      # end of group
      #
      @output.printf("</g><!-- end of plot area -->\n\n")


      #
      # draw legend
      #
      if @at_legend
        @output.printf("\n<!-- draw legends -->\n")
        if ! @at_legend[:y]
          @at_legend[:y] = (@height - @data_series.size * (@at_legend[:font_size] + @at_legend[:line_spacing])) / 2
          @at_legend[:y] = 0 if @at_legend[:y] < 0
        end

        attr = @at_legend.dup
        attr[:x] += 10
        attr[:y] += attr[:font_size]

        @data_series.each {|ds|
          @output.printf(%!<g%s>\n!, ds.id ? %! id="legend-#{ds.id}"! : "")

          @output.printf("  <text %s>%s</text>\n  ", make_common_attribute_string(attr), Alone::escape_html(ds.legend))
          ds.plot.draw_legend_marker(@output, attr[:x] - 10, (attr[:y] - attr[:font_size] / 3.0).to_i, ds)
          attr[:y] += attr[:font_size] + attr[:line_spacing]
          @output.printf("</g>\n")
        }
        @output.printf("\n")
      end

      #
      # draw x-axis title
      #
      if @at_xaxis_title
        @at_xaxis_title[:x] ||= @at_plot_area[:x] + @at_plot_area[:width] / 2
        @at_xaxis_title[:y] ||= @height - 5

        @output.printf("<text %s>%s</text>\n",
          make_common_attribute_string(@at_xaxis_title),
          Alone::escape_html(@at_xaxis_title[:node_value]))
      end

      #
      # draw x-axis unit
      #
      if @at_xaxis_unit
        @at_xaxis_unit[:x] ||= @at_plot_area[:x] + @at_plot_area[:width]
        @at_xaxis_unit[:y] ||= @height - 5

        @output.printf("<text %s>%s</text>\n",
          make_common_attribute_string(@at_xaxis_unit),
          Alone::escape_html(@at_xaxis_unit[:node_value]))
      end

      #
      # draw y-axis title
      #
      if @at_yaxis_title
        @at_yaxis_title[:x] ||= @at_yaxis_title[:font_size] + 5
        @at_yaxis_title[:y] ||= @at_plot_area[:y] + @at_plot_area[:height] / 2

        @output.printf(%!<text %s transform="rotate(-90,%d,%d)">%s</text>\n!,
          make_common_attribute_string(@at_yaxis_title),
          @at_yaxis_title[:x], @at_yaxis_title[:y],
          Alone::escape_html(@at_yaxis_title[:node_value]))
      end

      #
      # draw y-axis unit
      #
      if @at_yaxis_unit
        @at_yaxis_unit[:x] ||= @at_yaxis_unit[:font_size]
        @at_yaxis_unit[:y] ||= @at_plot_area[:y] - 6

        @output.printf(%!<text %s>%s</text>\n!,
          make_common_attribute_string(@at_yaxis_unit),
          Alone::escape_html(@at_yaxis_unit[:node_value]))
      end

      #
      # draw y2-axis unit
      #
      if @at_y2axis_unit
        @at_y2axis_unit[:x] ||= @at_plot_area[:x] + @at_plot_area[:width]
        @at_y2axis_unit[:y] ||= @at_plot_area[:y] - 6

        @output.printf(%!<text %s>%s</text>\n!,
          make_common_attribute_string(@at_y2axis_unit),
          Alone::escape_html(@at_y2axis_unit[:node_value]))
      end

      draw_common2()
    end

    ##
    # (Graph)
    # プロットエリアのマージン設定
    #
    #@param [Integer] top        上マージン
    #@param [Integer] right      右マージン
    #@param [Integer] bottom     下マージン
    #@param [Integer] left       左マージン
    #
    #  上下左右個別に設定できる。
    #  設定値を変えない場合は、そのパラメータをnilにしてcallする。
    #
    def set_margin(top, right, bottom, left)
      super

      # set axis objects parameters
      @x_axis.width = @at_plot_area[:width]
      @x_axis.height = @at_plot_area[:height]
      @y_axis.width = @at_plot_area[:width]
      @y_axis.height = @at_plot_area[:height]
      if @y2_axis
        @y2_axis.width = @at_plot_area[:width]
        @y2_axis.height = @at_plot_area[:height]
      end
    end

    ##
    # (Graph)
    # Ｘ軸タイトルの追加
    #
    #@param [String] title_string    タイトル文字列
    #
    def add_xaxis_title(title_string)
      set_margin(nil, nil, 35, nil)
      @at_xaxis_title =
        {:node_value=>title_string, :font_size=>12, :text_anchor=>'middle'}
    end

    ##
    # (Graph)
    # Ｘ軸単位表示の追加
    #
    #@param [String] unit_string    単位文字列
    #
    def add_xaxis_unit(unit_string)
      set_margin(nil, nil, 35, nil)
      @at_xaxis_unit =
        {:node_value=>unit_string, :font_size=>12, :text_anchor=>'middle'}
    end

    ##
    # (Graph)
    # Ｙ軸タイトルの追加
    #
    #@param [String] title_string    タイトル文字列
    #
    def add_yaxis_title(title_string)
      set_margin(nil, nil, nil, 50)
      @at_yaxis_title =
        {:node_value=>title_string, :font_size=>12, :text_anchor=>'middle'}
    end

    ##
    # (Graph)
    # Ｙ軸単位表示の追加
    #
    #@param [String] unit_string    単位文字列
    #
    def add_yaxis_unit(unit_string)
      set_margin(25, nil, nil, nil)
      @at_yaxis_unit =
        {:node_value=>unit_string, :font_size=>12, :text_anchor=>'start'}
    end


    ##
    # (Graph)
    # 第２Ｙ軸単位表示の追加
    #
    #@param [String] unit_string    単位文字列
    #
    def add_y2axis_unit(unit_string)
      set_margin(25, nil, nil, nil)
      @at_y2axis_unit =
        {:node_value=>unit_string, :font_size=>12, :text_anchor=>'start'}
    end

  end  # /Graph



  ##
  #  座標軸スーパークラス
  #
  class Axis < GraphView

    #@return [Hash]  軸アトリビュート
    attr_accessor :at_scale_line

    #@return [Hash]  目盛アトリビュート
    attr_accessor :at_interval_marks

    #@return [Hash]  目盛ラベルアトリビュート
    attr_accessor :at_labels

    #@return [Array, Nil]  目盛ラベル
    attr_accessor :labels

    #@return [Symbol, Nil] 目盛ラベル描画モード :LABEL_NORMAL :LABEL_INTERVAL
    attr_accessor :mode_label


    ##
    # (Axis)
    # constructor
    #
    #@param [Integer] width     幅
    #@param [Integer] height    高さ
    #
    def initialize(width, height)
      super

      # 軸アトリビュート
      @at_scale_line = {:stroke=>'black', :stroke_width=>1}
      # 目盛アトリビュート
      @at_interval_marks =
        {:length=>8, :stroke=>'#999999', :stroke_width=>1}
      # 目盛ラベルアトリビュート
      @at_labels = {:font_size=>10}

      @scale_mode = nil           # :ORDERED_LEFT :ORDERED_CENTER :LINER :LOGARITHMIC
      @scale_max = nil            # 目盛り最大値
      @scale_min = nil            # 目盛り最小値
      @scale_interval = nil       # 目盛り幅
      @scale_max_user = nil       # ユーザ設定目盛り最大値
      @scale_min_user = nil       # ユーザ設定目盛り最小値
      @scale_interval_user = nil  # ユーザ設定目盛り幅
      @scale_max_min= nil         # 最大値-最小値のキャッシュ
      @flag_reverse = false       # 目盛り逆方向（反転）フラグ
    end

    ##
    # (Axis)
    # 目盛り最大値のユーザ指定
    #
    #@param [Numeric] v    目盛り最大値
    #
    def set_max(v)
      @scale_max_user = v
    end
    alias max= set_max

    ##
    # (Axis)
    # 目盛り最大値を取得する
    #
    #@return [Numeric]     現在の目盛り最大値
    #
    def max()
      @scale_max
    end

    ##
    # (Axis)
    # 目盛り最小値のユーザ指定
    #
    #@param [Numeric] v    目盛り最小値
    #
    def set_min(v)
      @scale_min_user = v
    end
    alias min= set_min

    ##
    # (Axis)
    # 目盛り最小値を取得する
    #
    #@return [Numeric]     現在の目盛り最小値
    #
    def min()
      @scale_min
    end

    ##
    # (Axis)
    # 目盛り幅のユーザ指定
    #
    #@param [Numeric, Array<Numeric>] v    目盛り幅
    #
    def set_interval(v)
      @scale_interval_user = v
    end
    alias interval= set_interval

    ##
    # (Axis)
    # 目盛り逆方向（反転）指示
    #
    #@param [Boolean] f    true時、目盛りを反転させる
    #
    def reverse(f = true)
      @flag_reverse = f
    end

    ##
    # (Axis)
    # 対数目盛の指示
    #
    #@param [Boolean] f    true時、対数目盛にする
    #
    def logarithmic(f = true)
      @scale_mode = f ? :LOGARITHMIC : :LINER
    end

    ##
    # (Axis)
    # グリッド線の付与
    #
    def add_grid()
      @at_interval_marks[:grid] = true  if !@at_interval_marks.empty?
    end

    ##
    # (Axis)
    # グリッド線の消去
    #
    def clear_grid()
      @at_interval_marks[:grid] = false  if !@at_interval_marks.empty?
    end

    ##
    # (Axis)
    # 軸線の消去
    #
    def clear_scale_line()
      @at_scale_line.clear
    end

    ##
    # (Axis)
    # 間隔マークの消去
    #
    def clear_interval_marks()
      @at_interval_marks.clear
    end

    ##
    # (Axis)
    # 目盛ラベルの設定
    #
    #@param [Array] labels      目盛ラベル
    #
    def set_labels(labels)
      @labels = labels
    end

    ##
    # (Axis)
    # 目盛ラベルの消去
    #
    def clear_labels()
     @at_labels.clear
    end

    ##
    # (Axis)
    # 目盛りスケーリング
    #
    #@return [Boolean]     成功時、真
    #
    #  あらかじめ与えられているデータ系列情報などを元に、
    #  オートスケール処理など、内部データの整合性をとる。
    #
    def do_scaling()
      case @scale_mode
      when :ORDERED_LEFT, :ORDERED_CENTER
        do_scaling_ordered(:@x_data)
      when :LINER
        do_scaling_liner(:@y_data)
      when :LOGARITHMIC
        do_scaling_logarithmic(:@y_data)
      else
        raise
      end
    end


    private
    ##
    # (Axis)
    # 目盛りスケーリング　整列データ用
    #
    #@param [Symbol] x_or_y    対象の軸をシンボル値で指定
    #@return [Boolean]  成功時、真
    #
    #  典型的には、棒グラフのX軸のように、等長に整列されたデータに使用する。
    #
    def do_scaling_ordered( x_or_y )
      if @scale_max_user
        @scale_max = @scale_max_user
      else
        @scale_max = 0
        # 登録されているデータコンテナの、データ「数」の最大値を求める
        @data_series.each {|ds|
          @scale_max = [ds.size(), @scale_max].max
        }
        @scale_max -= 1
      end
      @scale_max = 0  if @scale_max < 0

      if @scale_min_user
        @scale_min = @scale_min_user
      else
        @scale_min = 0
      end

      if @scale_interval_user
        @scale_interval = @scale_interval_user
      else
        @scale_interval = 1
      end

      @scale_max_min = (@scale_max == @scale_min) ? 1 :
                       (@scale_max - @scale_min)
      return false if @scale_max_min < 0

      #
      # check scale interval value, and force adjust.
      #
      if !@scale_interval_user
        scale_px = case x_or_y
                   when :@x_data
                     @width
                   when :@y_data
                     @height
                   else
                     raise
                   end
        min_interval = (@scale_max - @scale_min).to_f * 5 / scale_px
        min_interval = 1 if min_interval < 1
        @scale_interval = min_interval  if @scale_interval < min_interval
      end

      return true
    end

    ##
    # (Axis)
    # 目盛りスケーリング　リニアスケール版
    #
    #@param [Symbol] x_or_y    対象の軸をシンボル値で指定
    #@return [Boolean]  成功時、真
    #
    def do_scaling_liner( x_or_y )
      # 登録されているデータコンテナの、データ「値」の最大、最小値を求める
      min = nil
      max = nil
      @data_series.each {|ds|
        (min1,max1) = ds.instance_variable_get(x_or_y).compact.minmax()
        next  if !max1
        min = min1  if !min || min > min1
        max = max1  if !max || max < max1
      }
      min ||= 0
      max ||= 0

      # max point adjustment.
      diff = max - min
      if diff == 0
        if max == 0
          max = 1
        else
          min -= min.abs * 0.5
          max += max.abs * 0.5
        end
      else
        max += diff * 0.1
      end

      # zero point adjustment.
      diff = max - min
      if min > 0 && diff * 2 > min
        min = 0
      elsif max < 0 && diff * 2 > -max
        max = 0
      end

      # refrect user settings.
      min = @scale_min_user if @scale_min_user
      max = @scale_max_user if @scale_max_user
      interval ||= @scale_interval_user

      # auto scaling.
      diff = max - min
      if diff > 0
        # calc interval.
        if ! @scale_interval_user
          # intervalがRationalオブジェクトになる場合がある？ .to_fで処置
          interval = (10 ** (Math.log10(diff).floor - 1)).to_f
          tick = diff / interval

          if tick > 55
            interval *= 10
          elsif tick > 27
            interval *= 5
          elsif tick > 22
            interval *= 2.5
          elsif tick > 11
            interval *= 2
          end
        end

        # max and min point adjustment.
        max = (max / interval).ceil * interval if ! @scale_max_user
        min = (min / interval).floor * interval if ! @scale_min_user
      end

      return false if ! interval

      # check scale interval value, and force adjust.
      scale_px = case x_or_y
                 when :@x_data
                   @width
                 when :@y_data
                   @height
                 else
                   raise
                 end
      min_interval = diff.to_f * 5 / scale_px
      interval = min_interval  if interval < min_interval

      @scale_min = min
      @scale_max = max
      @scale_max_min = (max == min) ? 1.0 : (max - min).to_f
      @scale_interval = interval

      return true
    end

    ##
    # (Axis)
    # 目盛りスケーリング　ログスケール版
    #
    #@param [Symbol] x_or_y    対象の軸をシンボル値で指定
    #@return [Boolean]  成功時、真
    #
    def do_scaling_logarithmic( x_or_y )
      # 登録されているデータコンテナの、データ「値」の最大、最小値を求める
      # （異常値は除く）
      min = nil
      max = nil
      @data_series.each {|ds|
        (min1,max1) = ds.instance_variable_get(x_or_y).compact.minmax()
        next  if !max1 || max1 <= 0
        if min1 <= 0
          min1 = nil
          ds.instance_variable_get(x_or_y).each {|v|
            next      if !v    || v <= 0.0
            min1 = v  if !min1 || min1 > v
          }
        end
        min = min1  if !min || min > min1
        max = max1  if !max || max < max1
      }
      min ||= 1
      max ||= 10

      min = (10 ** Math.log10( min ).floor).to_f
      max = (10 ** Math.log10( max ).ceil).to_f
      # (note)
      #  min値は、1**n であることを期待したコードが、draw_z* メソッドにある。

      min = @scale_min_user if @scale_min_user
      max = @scale_max_user if @scale_max_user

      @scale_min = min
      @scale_max = max
      @scale_max_min = Math.log10(max / min).to_f
      @scale_interval = @scale_interval_user || [1]
      if @scale_interval.class != Array
        raise "#{self.class}.interval must be array."
      end

      return true
    end

    ##
    # (Axis)
    # 描画　1st pass
    #  スケール描画　パス１用サブルーチン　グリッド線の描画
    #
    #@param [Object] output     出力先
    #@param [String] fmt        表示フォーマット
    #                           e.g. '<line x1="0" y1="%d" x2="8" y2="%d" />'
    #
    def draw_z1_sub( output, fmt )
      output.printf("<g %s>\n", make_common_attribute_string(@at_interval_marks))

      case @scale_mode
      when :LINER
        # リニア目盛
        ofs = (@scale_min > 0 || @scale_max < 0) ? @scale_min : 0
        i = 0
        step = 1
        while step >= -1
          v = @scale_interval * i + ofs
          if v > @scale_max || v < @scale_min
            step -= 2
            i = -1
            next
          end

          v = calc_pixcel_position(v)
          output.printf(fmt, v, v)
          i += step
        end

      when :LOGARITHMIC
        # 対数目盛
        i = 1
        v = v0 = @scale_min
        while v <= @scale_max
          v = calc_pixcel_position(v)
          output.printf(fmt, v, v)
          if (i += 1) >= 10
            i = 1
            v0 *= 10
          end
          v = v0 * i
        end
      end

      output.printf("</g>\n")
    end

    ##
    # (Axis)
    # ラベル（数値）の描画
    #
    #@param [Object] output     出力先
    #@yield [v]
    #@yieldreturn [Hash] x,y,vの値が入ったHash
    #
    def draw_labels( output )
      labels = []

      # 表示位置(XY)計算
      case @scale_mode
      when :LINER
        # リニア目盛
        ofs = (@scale_min > 0 || @scale_max < 0) ? @scale_min : 0
        i = 0
        step = 1
        while step >= -1
          v = @scale_interval * i + ofs
          if v > @scale_max || v < @scale_min
            step -= 2
            i = -1
            next
          end
          labels << yield(v)
          i += step
        end
        if @labels
          labels.sort_by! {|label| label[:y] }
          labels.reverse!
          labels.each_with_index {|label, i|
            label[:l] = @labels[i] ? Alone::escape_html(@labels[i]) : ""
          }
        end

      when :LOGARITHMIC
        # 対数目盛
        i = j = 0
        v0 = @scale_min
        while (v = v0 * @scale_interval[j]) <= @scale_max
          labels << yield(v)
          if @labels
            labels.last[:l] = @labels[i] ? Alone::escape_html(@labels[i]) : ""
          end
          if (j += 1) >= @scale_interval.size
            j = 0
            v0 *= 10
          end
          i += 1
        end
      end

      # add label string.
      if @labels
        # already done.
      elsif @at_labels[:renderer]
        labels.each {|label|
          label[:l] = @at_labels[:renderer].call( label[:v] )
        }
      elsif @at_labels[:format]
        labels.each {|label|
          label[:l] = sprintf( @at_labels[:format], label[:v] )
        }
      else
        # to string and reform length
        len = []
        labels.each {|label|
          label[:l] = label[:v].to_s
          len[ label[:l].length ] = len[ label[:l].length ].to_i + 1  # 頻度を求める
        }
        th = len.index( len.compact.max ) + 5
        labels.each_with_index {|label, i|
          next if label[:l].length < th
          (1..5).each {|j|
            if labels[i+j] && labels[i+j][:l].length < th
              label[:l] = label[:l][0, labels[i+j][:l].length]
              break
            end
            if labels[i-j] && labels[i-j][:l].length < th
              label[:l] = label[:l][0, labels[i-j][:l].length]
              break
            end
          }
        }
      end

      # draw
      output.printf("<g %s>\n", make_common_attribute_string(@at_labels))
      labels.each {|label|
        if !@at_labels[:rotate]
          output.printf(%!  <text x="%d" y="%d">%s</text>\n!,
                label[:x], label[:y], label[:l])
        else
          output.printf(%!  <text x="%d" y="%d" transform="rotate(%d,%d,%d)">%s</text>\n!,
                label[:x], label[:y], @at_labels[:rotate],
                label[:x], label[:y] - @at_labels[:font_size] / 2, label[:l])
        end
      }
      output.printf("</g>\n")
    end

  end  # /Axis


  ##
  # X軸クラス
  #
  class XAxis < Axis

    ##
    # (XAxis)
    # constructor
    #
    #@param [Integer] width     幅
    #@param [Integer] height    高さ
    #
    def initialize(width, height)
      super

      @scale_mode = :ORDERED_LEFT
      @at_interval_marks[:grid] = false
    end

    ##
    # (XAxis)
    # 軸描画モード変更
    #
    #@param [Symbol] mode    軸描画モード(:LEFT | :CENTER)
    #
    def change_mode(mode)
      mode_sym = "ORDERED_#{mode}".to_sym
      case mode_sym
      when :ORDERED_LEFT, :ORDERED_CENTER
        @scale_mode = mode_sym
      end
    end

    ##
    # (XAxis)
    # 目盛り最大値のユーザ指定 (override)
    #
    #@param [Numeric] v   目盛り最大値
    #
    def set_max(v)
      @scale_max_user = v - 1
    end

    ##
    # (XAxis)
    # 目盛り最小値のユーザ指定 (override)
    #
    #@param [Numeric] v   目盛り最小値
    #
    def set_min(v)
      @scale_min_user = v - 1
    end

    ##
    # (XAxis)
    # 軸上のピクセル位置を計算する。
    #
    #@param [Numeric] v    実数
    #@return [Integer]     ピクセル位置
    #
    #  引数が軸上にない場合、返り値も軸上にはないピクセル位置が返る。
    #
    def calc_pixcel_position(v)
      case @scale_mode
      when :ORDERED_LEFT
        return (@width * (v - @scale_min) / @scale_max_min).to_i
      when :ORDERED_CENTER
        return ((2 * @width * (v - @scale_min) + @width) / (@scale_max_min + 1) / 2).to_i
      else
        raise "Not support #{@scale_mode} mode."
      end
    end

    ##
    # (XAxis)
    # 描画　1st pass
    #
    #  スケール描画　パス１。
    #
    #@param [Object] output     出力先
    #
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

      output.printf("<g %s>\n", make_common_attribute_string(@at_interval_marks))

      case @scale_mode
      when :ORDERED_LEFT
        i = @scale_min
        while i <= @scale_max do
          x = calc_pixcel_position(i)
          output.printf(%!  <line x1="%d" y1="%d" x2="%d" y2="%d" />\n!, x, y1, x, y2)
          i += @scale_interval
        end

      when :ORDERED_CENTER
        max_loops = (@scale_max - @scale_min) / @scale_interval + 1
        i = 0
        while i <= max_loops do
          x = (@width * i / max_loops.to_f).to_i
          output.printf(%!  <line x1="%d" y1="%d" x2="%d" y2="%d" />\n!, x, y1, x, y2)
          i += 1
        end

      else
        raise "Not support #{@scale_mode} mode."
      end
      output.printf("</g>\n")
    end

    ##
    # (XAxis)
    # 描画　2nd pass
    #
    #  スケール描画　パス２。
    #
    #@param [Object] output     出力先
    #@visibility private
    def draw_z2( output )
      output.printf("\n<!-- draw X-axis pass 2 -->\n")

      #
      # draw scale line
      #
      if !@at_scale_line.empty?
        output.printf(%!<line x1="%d" y1="%d" x2="%d" y2="%d" %s />\n!,
                      0, @height, @width, @height,
                      make_common_attribute_string(@at_scale_line))
      end

      return if @at_labels.empty?

      #
      # draw labels
      #
      adjust_text_anchor()
      output.printf("<g %s>\n", make_common_attribute_string(@at_labels))
      i = -1
      while (v = @scale_min + @scale_interval * (i += 1)) <= @scale_max
        if !@labels
          label = sprintf("%d", (v+1).to_i)
        else
          label = (@mode_label == :LABEL_INTERVAL) ? @labels[i] : @labels[v]
          next if !label
          label = Alone.escape_html(label)
        end

        x = calc_pixcel_position(v)
        y = @height + @at_labels[:font_size] + 5
        if !@at_labels[:rotate]
          output.printf(%!  <text x="%d" y="%d">%s</text>\n!, x, y, label)
        else
          output.printf(%!  <text x="%d" y="%d" transform="rotate(%d,%d,%d)" >%s</text>\n!, x, y, @at_labels[:rotate], x, y - @at_labels[:font_size] / 2, label)
        end
      end
      output.printf("</g>\n")
    end


    private
    ##
    # (XAxis)
    # テキストアンカー位置の決定
    #
    def adjust_text_anchor()
      return if @at_labels[:text_anchor]

      @at_labels[:text_anchor] = 'middle'

      # 回転させる時は、回転角に応じて自動調整
      if @at_labels[:rotate]
        if 0 < @at_labels[:rotate] && @at_labels[:rotate] < 180
          @at_labels[:text_anchor] = 'start'
        elsif -180 < @at_labels[:rotate] && @at_labels[:rotate] < 0
          @at_labels[:text_anchor] = 'end'
        end
      end
    end

  end  # /XAxis


  ##
  # Y軸クラス
  #
  class YAxis < Axis

    ##
    # (Yxis)
    # constructor
    #
    #@param [Integer] width     幅
    #@param [Integer] height    高さ
    #
    def initialize(width, height)
      super

      @scale_mode = :LINER
      @at_labels[:text_anchor] = 'end'
      @at_interval_marks[:grid] = true
    end

    ##
    # (YAxis)
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
        y = (@height * (v - @scale_min) / @scale_max_min).to_i
      when :LOGARITHMIC
        y = (@height * Math.log10(v/@scale_min) / @scale_max_min).to_i
      else
        raise "Not support #{@scale_mode} mode."
      end
      return @flag_reverse ? y : @height - y
    end

    ##
    # (YAxis)
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
      output.printf("\n<!-- draw Y-axis pass 1 -->\n")
      if @at_interval_marks[:length] < 0
        x1 = @at_interval_marks[:length]
        x2 = 0
      else
        x1 = 0
        x2 = @at_interval_marks[:length]
      end
      if @at_interval_marks[:grid]
        x2 = @width
      end

      draw_z1_sub(output, %!  <line x1="#{x1}" y1="%d" x2="#{x2}" y2="%d" />\n!)
    end

    ##
    # (YAxis)
    # 描画　2nd pass
    #
    #  スケール描画　パス２　Y軸縦線、ラベル（数値）の描画
    #
    #@param [Object] output     出力先
    #@visibility private
    def draw_z2( output )
      output.printf("\n<!-- draw Y-axis pass 2 -->\n")

      # draw scale line
      if ! @at_scale_line.empty?
        output.printf(%!<line x1="%d" y1="%d" x2="%d" y2="%d" %s />\n!,
                      0, 0, 0, @height,
                      make_common_attribute_string(@at_scale_line))
      end

      # draw labels
      if !@at_labels.empty?
        draw_labels(output) {|v|
          {:x=>-5,
           :y=>calc_pixcel_position(v) + @at_labels[:font_size] / 2,
           :v=>v}
        }
      end
    end

  end  # /YAxis


  ##
  # 第２Ｙ軸クラス
  #
  class Y2Axis < YAxis

    ##
    # (Y2xis)
    # constructor
    #
    #@param [Integer] width     幅
    #@param [Integer] height    高さ
    #
    def initialize(width, height)
      super

      @at_labels[:text_anchor] = 'start'
      @at_interval_marks[:grid] = false
    end

    ##
    # (Y2Axis)
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
      output.printf("\n<!-- draw Y2-axis pass 1 -->\n")
      if @at_interval_marks[:length] < 0
        x1 = @width - @at_interval_marks[:length]
        x2 = @width
      else
        x1 = @width
        x2 = @width - @at_interval_marks[:length]
      end
      if @at_interval_marks[:grid]
        x2 = 0
      end

      draw_z1_sub(output, %!  <line x1="#{x1}" y1="%d" x2="#{x2}" y2="%d" />\n!)
    end

    ##
    # (Y2Axis)
    # 描画　2nd pass
    #
    #  スケール描画　パス２　Y軸縦線、ラベル（数値）の描画
    #
    #@param [Object] output     出力先
    #@visibility private
    def draw_z2( output )
      output.printf("\n<!-- draw Y2-axis pass 2 -->\n")

      # draw scale line
      if ! @at_scale_line.empty?
        output.printf(%!<line x1="%d" y1="%d" x2="%d" y2="%d" %s />\n!,
                      @width, 0, @width, @height,
                      make_common_attribute_string(@at_scale_line))
      end

      # draw labels
      if !@at_labels.empty?
        draw_labels(output) {|v|
          {:x=>@width + 5,
           :y=>calc_pixcel_position(v) + @at_labels[:font_size] / 2,
           :v=>v}
        }
      end
    end

  end  # /Y2Axis



  ##
  #  折れ線グラフプロットクラス
  #
  class LinePlot < GraphView

    ##
    # (LinePlot)
    # 描画
    #
    #  管理下のデータコンテナすべてについて、実際に描画を行う。
    #
    #@param [Object] output     出力先
    #@visibility private
    def draw( output )
      @data_series.each {|ds|
        output.printf("\n<!-- draw line-plot '%s' -->\n", ds.legend)

        #
        # Plot poly line.
        #
        if !ds.at_plot_line.empty?
          mark_start = nil
          ds.each {|xd, yd, i|
            begin
              if yd
                x = ds.x_axis.calc_pixcel_position(xd)
                y = ds.y_axis.calc_pixcel_position(yd)  # log10(-1)等のエラーチェックを兼ねる
                if !mark_start
                  mark_start = [x,y]
                  next
                end
                if mark_start.is_a?(Array)
                  output.printf(%!<polyline%s points="%d,%d !,
                                (ds.id ? %! id="#{ds.id}"! : ""),
                                mark_start[0], mark_start[1])
                  mark_start = :CONTINUOUS
                end
                output.printf("%d,%d ", x, y )

              elsif ds.mode_missing_data == :MODE_BREAK  # && !yd
                if mark_start == :CONTINUOUS
                  output.printf(%!" %s />\n!, make_common_attribute_string(ds.at_plot_line))
                end
                mark_start = nil
              end
            rescue
              # nothing to do.
            end
          }
          if mark_start == :CONTINUOUS
            output.printf(%!" %s />\n!, make_common_attribute_string(ds.at_plot_line))
          end
        end

        #
        # Plot markers
        #
        if !ds.at_marker.empty?
          output.printf("<g %s>\n", make_common_attribute_string(ds.at_marker))
          ds.each {|xd, yd, i|
            begin
              attr = {:shape=>ds.at_marker[:shape], :size=>ds.at_marker[:size]}
              attr.merge!( ds.at_marker_several[i] ) if ds.at_marker_several[i]
              draw_marker( output, ds.x_axis.calc_pixcel_position(xd),
                                   ds.y_axis.calc_pixcel_position(yd), attr )
            rescue
              # nothing to do.
            end
          }
          output.printf("</g>\n")
        end

        #
        # Data labels.
        #
        if ds.at_data_labels
          output.printf("<g %s>\n", make_common_attribute_string(ds.at_data_labels))
          ds.each {|xd, yd, i|
            begin
              x = ds.x_axis.calc_pixcel_position(xd)
              y = ds.y_axis.calc_pixcel_position(yd)
              case ds.at_data_labels[:position]
              when :ABOVE
                y -= 6
              when :BELOW
                y += ds.at_data_labels[:font_size] + 6
              when :LEFT
                x -= 6
                y += ds.at_data_labels[:font_size] / 2
              when :RIGHT
                x += 6
                y += ds.at_data_labels[:font_size] / 2
              when :CENTER
                y += ds.at_data_labels[:font_size] / 2
              end

              output.printf('  <text x="%d" y="%d">', x, y)
              if ds.labels
                output.printf("%s", Alone.escape_html(ds.labels[i].to_s))
              elsif ds.at_data_labels[:format]
                output.printf("#{ds.at_data_labels[:format]}", yd)
              else
                output.printf("%s", yd.to_s)
              end
              output.printf("</text>\n")
            rescue
              # nothing to do
            end
          }
          output.printf("</g>\n")
        end
      }
    end


    ##
    # (LinePlot)
    # マーカーを描画する
    #
    #@param [Object] output     出力先
    #@param [Integer] x         Ｘ値
    #@param [Integer] y         Ｙ値
    #@param [Hash] attr         描画アトリビュート
    #@option attr [Symbol] :shape
    #   マーカ種類 (:circle | :rectangle | :diamond | triangle | :cock)
    #@option attr [Integer] :size マーカの大きさ
    #@option attr [String,Integer] :OTHERS その他SVGに出力するアトリビュート
    #
    #@visibility private
    def draw_marker(output, x, y, attr)
      attrstr = make_common_attribute_string( attr )

      case attr[:shape] && attr[:shape].to_sym
      when :circle
        r = attr[:size] || 4
        output.printf(%!  <circle cx="%d" cy="%d" r="%d" %s/>\n!, x, y, r, attrstr)

      when :rectangle
        r = attr[:size] || 4
        output.printf(%!  <rect x="%d" y="%d" width="%d" height="%d" %s/>\n!, x-r, y-r, r*2, r*2, attrstr)

      when :diamond
        r = attr[:size] || 5
        output.printf(%!  <polygon points="%d,%d %d,%d %d,%d %d,%d" %s/>\n!, x-r, y, x, y-r, x+r, y, x, y+r, attrstr)

      when :triangle
        r = attr[:size] || 5
        output.printf(%!  <polygon points="%d,%d %d,%d %d,%d" %s/>\n!, x, y-r, x-r, y+r, x+r, y+r, attrstr)

      when :cock
        r = attr[:size] || 4
        output.printf(%!  <polygon points="%d,%d %d,%d %d,%d %d,%d" %s/>\n!, x-r, y-r, x+r, y+r, x+r, y-r, x-r, y+r, attrstr)

      end
    end

    ##
    # (LinePlot)
    # 凡例部マーカー描画
    #
    #@param [Object] output     出力先
    #@param [Integer] x         Ｘ値
    #@param [Integer] y         Ｙ値
    #@param [DataContainer] data_obj   データコンテナオブジェクト
    #
    #@visibility private
    def draw_legend_marker(output, x, y, data_obj)
      if !data_obj.at_plot_line.empty?
        output.printf(%!<line x1="%d" y1="%d" x2="%d" y2="%d" %s/>\n!,
                      x-9, y, x+9, y,
                      make_common_attribute_string(data_obj.at_plot_line))
      end

      if !data_obj.at_marker.empty?
        attr = { :shape=>data_obj.at_marker[:shape] }
        attr.merge!( data_obj.at_marker )
        draw_marker(output, x, y, attr)
      end
    end

  end  # /LinePlot


  ##
  # バーグラフプロットクラス
  #
  class BarPlot < GraphView

    #@return [Numeric]  棒のオーバーラップ率（％）
    attr_reader :overlap

    #@return [Numeric]  棒の間隔率（％：100%で軸とスペースが同じ幅）
    attr_reader :spacing


    ##
    # (BarPlot)
    # constructor
    #
    def initialize( width, height )
      super
      @overlap = 0
      @spacing = 100
    end

    ##
    # (BarPlot)
    # データコンテナ追加
    #
    #@param [ContainerBar] data_obj  データコンテナオブジェクト
    #@param [ContainerBar] base_bar  積み重ねする場合、ベースになるデータコンテナ
    #
    def add_data_series(data_obj, base_bar)
      if base_bar
        @data_series.each_with_index {|ds, i|
          if ds == base_bar
            @data_series.insert(i, data_obj)
            break
          end
        }
      else
        @data_series << data_obj
      end
    end

    ##
    # (BarPlot)
    # 棒どうしのオーバーラップ率指定
    #
    #@param [Integer] v  オーバーラップ率 (%)
    #
    #  0から100を指定する。
    #
    def set_overlap(v)
      @overlap = v
    end
    alias overlap= set_overlap

    ##
    # (BarPlot)
    # 棒どうしの間隔指定
    #
    #@param [Integer] v    間隔率 (%)
    #
    #  0から100を指定する。
    #
    def set_spacing(v)
      @spacing = v
    end
    alias spacing= set_spacing

    ##
    # (BarPlot)
    # 描画
    #
    #  管理下のデータコンテナすべてについて、実際に描画を行う。
    #
    #@param [Object] output     出力先
    #@visibility private
    def draw( output )
      num = @data_series.size
      @data_series.each {|ds|
        num -= 1 if ds.base_container
      }

      ov = 1 - @overlap / 100.0   # 棒のオーバーラップ率
      sp = @spacing / 100.0       # 棒幅に対する棒間の率
      w_all = @data_series[0].x_axis.calc_pixcel_position(1) -
        @data_series[0].x_axis.calc_pixcel_position(0) # 全幅 (px)
      w_b = w_all / ( 1 + ov * (num - 1) + sp)  # 棒幅 (px)
      w_s = w_b * sp / 2          # 間隔幅 (px)

      n = 0
      @data_series.each {|ds|
        output.printf("\n<!-- draw bar-plot '%s' -->\n", ds.legend)

        #
        # Draw bar (1 series)
        #
        output.printf("<g %s>\n", make_common_attribute_string(ds.at_bar))
        ds.each {|xd, yd, i|
          next if !yd

          x = ds.x_axis.calc_pixcel_position(xd) - (w_all / 2.0)
          x1 = x + w_s + n * w_b * ov
          x2 = x1 + w_b
          if ! ds.base_container
            y1 = ds.y_axis.calc_pixcel_position(0)
          else
            y = ds.base_container.y_data[i] || 0
            y1 = ds.y_axis.calc_pixcel_position(y)
          end
          y2 = ds.y_axis.calc_pixcel_position(yd)
          next  if y1 == y2

          output.printf(%!  <polyline points="%.2f,%.2f %.2f,%.2f %.2f,%.2f %.2f,%.2f"!, x1, y1, x1, y2, x2, y2, x2, y1)
          if ds.at_bar_several[i]
            output.printf(" %s", make_common_attribute_string(ds.at_bar_several[i]))
          end
          output.printf(" />\n")
        }
        output.printf("</g>\n")

        #
        # Data labels.
        #
        if ds.at_data_labels
          output.printf("<g %s>\n", make_common_attribute_string(ds.at_data_labels))
          ds.each {|xd, yd, i|
            next if !yd

            x = ds.x_axis.calc_pixcel_position(xd) - (w_all / 2) + w_s +
              n * w_b * ov
            y = ds.y_axis.calc_pixcel_position(yd)

            case ds.at_data_labels[:position]
            when :ABOVE
              x += w_b / 2
              y -= 6
            when :BELOW
              x += w_b / 2
              y += ds.at_data_labels[:font_size] + 6
            when :LEFT
              x -= 3
              y += ds.at_data_labels[:font_size] / 2
            when :RIGHT
              x += w_b + 3
              y += ds.at_data_labels[:font_size] / 2
            when :CENTER
              x += w_b / 2
              y += ds.at_data_labels[:font_size] / 2
            end

            output.printf('  <text x="%d" y="%d">', x, y)
            if ds.at_data_labels[:format]
              output.printf("#{ds.at_data_labels[:format]}</text>", yd)
            else
              output.printf("%s</text>\n", yd.to_s)
            end
          }

          output.printf("</g>\n")
        end

        n += 1 if ! ds.base_container
      }
    end

    ##
    # (BarPlot)
    # 凡例部マーカー描画
    #
    #@param [Object] output     出力先
    #@param [Integer] x         Ｘ値
    #@param [Integer] y         Ｙ値
    #@param [ContainerBar] data_obj    データコンテナオブジェクト
    #
    #@visibility private
    def draw_legend_marker(output, x, y, data_obj)
      output.printf(%!<rect x="%d" y="%d" width="8" height="8" %s/>\n!,
                    x - 3, y - 3, make_common_attribute_string(data_obj.at_bar))
    end

  end  # /BarPlot



  ##
  #  データコンテナ　スーパークラス
  #
  class DataContainer

    #@return [String] ID
    attr_accessor :id

    #@return [Array<Numeric>] Y値データ
    attr_accessor :y_data

    #@return [Hash,Nil] データラベルアトリビュート
    attr_accessor :at_data_labels

    #@return [Array,Nil]  データラベル
    attr_accessor :labels

    #@return [String] 凡例文字列
    attr_accessor :legend

    #@return [XAxis] 使用するＸ軸オブジェクト
    attr_accessor :x_axis

    #@return [YAxis] 使用するＹ軸オブジェクト
    attr_accessor :y_axis

    #@return [LinePlot,BarPlot] 使用するプロットオブジェクト
    attr_accessor :plot


    ##
    # (DataContainer)
    # constructor
    #
    #@param [Array<Numeric>] ydata   Y値データ
    #@param [String] legend          凡例文字列
    #
    def initialize(ydata, legend = nil)
      @y_data = ydata
      @legend = legend
    end

    ##
    # (DataContainer)
    # 値ラベルを表示
    #
    #@param [String,Symbol] pos  値ラベルの位置 (ABOVE|BELOW|LEFT|RIGHT|CENTER)
    #
    #  位置以外は、デフォルト値で表示するよう設定。
    #
    def add_data_labels(pos = :ABOVE)
      pos = pos.to_sym
      case pos
      when :ABOVE, :BELOW, :CENTER
        @at_data_labels = {position:pos, font_size:9, text_anchor:'middle'}
      when :LEFT
        @at_data_labels = {position:pos, font_size:9, text_anchor:'end'}
      when :RIGHT
        @at_data_labels = {position:pos, font_size:9, text_anchor:'start'}
      else
        raise "Illegal parameter #{pos}"
      end
    end

    ##
    # (DataContainer)
    # データ数を返す
    #
    def size()
      return @y_data.size()
    end

    ##
    # (DataContainer)
    # イテレータ
    #
    def each()
      @y_data.each_with_index {|yd, i|
        yield( i, yd ,i )
      }
    end

  end  # /DataContainer


  ##
  # 折れ線グラフ用データコンテナ
  #
  # 線を消してマーカのみの表示にすることもできる。
  #
  class ContainerLine < DataContainer

    #@return [Hash] 線の描画アトリビュート
    attr_accessor :at_plot_line

    #@return [Hash] マーカーの描画アトリビュート
    attr_accessor :at_marker

    #@return [Array<Hash>] 個別のマーカーの描画アトリビュート
    attr_accessor :at_marker_several

    #@return [Symbol] 欠損データに対する描画モード :MODE_CONTINUOUS :MODE_BREAK
    attr_accessor :mode_missing_data


    ##
    # (ContainerLine)
    # constructor
    #
    #@param [Array<Numeric>] ydata   Y値データ
    #@param [String] legend          凡例文字列
    #
    def initialize(ydata, legend = nil)
      super

      @at_plot_line = {:stroke_width=>2, :fill=>:none}
      @at_marker = {:format=>nil, :stroke=>:black, :stroke_width=>2}
      @at_marker_several = []
      @mode_missing_data = :MODE_CONTINUOUS
    end

    ##
    # (ContainerLine)
    # 線を表示しない
    #
    def clear_line()
      @at_plot_line.clear
    end

    ##
    # (ContainerLine)
    # マーカーを表示しない
    #
    def clear_marker()
      @at_marker.clear
    end

    ##
    # (ContainerLine)
    # 色の指定
    #
    #@param [String] color   色(HTMLカラーコード)
    #
    #  折れ線の場合、線とマーカーの両方の色変えなければならないので、
    #  アトリビュートを2ヶ所変更するよりも簡単にするために作成。
    #
    def set_color(color)
      @at_plot_line[:stroke] = color if !@at_plot_line.empty?
      @at_marker[:fill] = color if !@at_marker.empty?
    end
    alias color= set_color

  end  # /ContainerLine


  ##
  #  バーグラフ用データコンテナ
  #
  class ContainerBar < DataContainer

    #@return [Hash] バーの描画アトリビュート
    attr_accessor :at_bar

    #@return [Hash<Hash>] 個別のバー描画アトリビュート
    attr_accessor :at_bar_several

    #@return [Containerbar] 積み重ねグラフの時、下になるコンテナオブジェクト
    attr_reader :base_container


    ##
    # (ContainerBar)
    # constructor
    #
    #@param [Array<Numeric>] ydata   Y値データ
    #@param [String] legend          凡例文字列
    #
    def initialize(ydata, legend = nil)
      super

      @at_bar = {:stroke_width=>1, :stroke=>:black}
      @at_bar_several = {}
      @base_container = nil
    end

    ##
    # (ContainerBar)
    # 積み重ね設定
    #
    #@param [ContainerBar] base    ベースになるデータコンテナ
    #
    def set_stack(base)
      @base_container = base
    end

    ##
    # (ContainerBar)
    # 色の指定
    #
    #@param [String] color   色(HTMLカラーコード)
    #
    #  ContainerLine::color= との対称性のため定義。
    #
    def set_color(color)
      @at_bar[:fill] = color
    end
    alias color= set_color

  end  # /ContainerBar


  ##
  # AlGraph::Graphのインスタンス生成
  #
  # AlGraph::Graphのインスタンスを生成して返す。
  # AlGraph::Graph.newのかわりにAlGraph.newと書くことができる。
  #
  def self.new(*params)
    AlGraph::Graph.new(*params)
  end

end  # /AlGraph
