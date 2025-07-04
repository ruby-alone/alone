# -*- coding: utf-8 -*-
# alone : application framework for small embedded systems.
#   Copyright (c) 2010-2017
#                 Inas Co Ltd., FAR END Technologies Corporation,
#                 All Rights Reserved.
#   Copyright (c) 2021-2022 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2021-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the COPYRIGHT file.
#
# 基本的なクラスを定義
#
#  GraphView - GraphBase
#  AutoScaleError*
#

##
# AlGraphの各クラスのための名前空間
#
module AlGraph

  class AutoScaleErrorX < StandardError; end    # X軸オートスケールエラー
  class AutoScaleErrorY < StandardError; end    # Y軸オートスケールエラー
  class AutoScaleErrorY2 < StandardError; end   # Y2軸オートスケールエラー

  ##
  #  描画機能のベースクラス
  #
  class GraphView

    # make_common_attribute_string()用アトリビュート制御テーブル
    # 値がnilなら無視するアトリビュート、Stringならそれにリネームする。
    ATTR_NAMES = {
      # ignores
      :node_value => nil,
      :format => nil,
      :grid => nil,
      :image => nil,
      :length => nil,
      :position => nil,
      :rotate => nil,
      :separate_distance => nil,
      :shape => nil,
      :size => nil,
      :line_spacing => nil,
      :renderer => nil,

      # stroke styles
      :stroke_width => "stroke-width",
      :stroke_dasharray => "stroke-dasharray",
      # fonts
      :font_size => "font-size",
      :font_family => "font-family",
      :font_weight => "font-weight",
      :font_style => "font-style",
      :text_anchor => "text-anchor",
      :text_decoration => "text-decoration",
      # opacity
      :stroke_opacity => "stroke-opacity",
      :fill_opacity => "fill-opacity",
    }

    #@return [Integer] 占める領域の幅
    attr_accessor :width

    #@return [Integer] 占める領域の高さ
    attr_accessor :height

    #@return [Array<DataContainer>] データコンテナの配列
    attr_reader :data_series


    ##
    # (GraphView)
    # constructor
    #
    #@param [Integer] width          幅
    #@param [Integer] height         高さ
    #
    def initialize(width, height)
      @width = width
      @height = height
      @data_series = []
    end

    protected
    ##
    # (GraphView)
    # データコンテナ追加
    #
    #@param [DataContainer] data_obj  データコンテナオブジェクト
    #
    def add_data_series(data_obj)
      @data_series << data_obj
    end

    ##
    # (GraphView)
    # アトリビュート文字列生成
    #
    #@param  [Hash] attrs      アトリビュートを格納したハッシュ
    #@return [String]          アトリビュート文字列
    #
    #  引数で与えた連想配列 (array) の、特定のキーから xml アトリビュート
    #  文字列を生成して返す。
    #  値がnil、および無視リストに登録があるアトリビュートは対象外とする。
    #
    def make_common_attribute_string(attrs)
      s = ""
      attrs.each {|k,v|
        next if v == nil
        attr_name = ATTR_NAMES.fetch(k.to_sym) rescue k
        if attr_name == "font-size"
          s << %!#{attr_name}="#{v}px" !
        elsif attr_name
          s << %!#{attr_name}="#{v}" !
        end
      }
      s.chop!
      return s
    end

  end  # /GraphView



  ##
  #  各グラフのベースクラス
  #
  class GraphBase < GraphView

    COLOR_LIST = [
      '#004586', '#ff420e', '#ffd320', '#579d1c', '#7e0021', '#83caff',
      '#314004', '#aecf00', '#4b1f6f', '#ff950e', '#c5000b', '#0084d1' ]

    #@return [String] ID
    attr_accessor :id

    #@return [Hash] グラフエリアアトリビュート
    attr_accessor :at_graph_area

    #@return [Hash] プロットエリアアトリビュート
    attr_accessor :at_plot_area

    #@return [Hash]  メインタイトルアトリビュート
    attr_accessor :at_main_title

    #@return [Hash]  凡例アトリビュート
    attr_accessor :at_legend

    #@return [Array<String>] 色リスト
    attr_accessor :color_list

    #@return [Kernel,StringIO] 出力制御オブジェクト
    attr_accessor :output


    ##
    # (GraphBase)
    # constructor
    #
    #@param [Integer] width     幅
    #@param [Integer] height    高さ
    #@param [String]  id        ID
    #
    def initialize(width, height, id)
      super( width, height )

      @id = id
      @at_graph_area = { :width=>@width, :height=>@height,
                         :stroke_width=>1, :stroke=>"black", :fill=>"white" }
      @at_plot_area = { :x=>0, :y=>0, :width=>0, :height=>0 }
      @at_main_title = nil
      @at_legend = nil
      @color_list = COLOR_LIST

      # 追加任意タグ
      @aux_tags = []
      # 動作モード (see set_mode() function.)
      @work_mode = {:SVGTAG_START=>true, :SVGTAG_END=>true}

      @output = Kernel
    end

    ##
    # (GraphBase)
    # 動作モード指定
    #
    #@param  [Symbol] mode   動作モード
    #
    #  設定可能モード（先頭にNOをつけると意味を反転）
    #   :CONTENT_TYPE     ContentType ヘッダを出力する／しない
    #   :XML_DECLARATION  XML宣言およびDOCTYPE宣言を出力する／しない
    #   :SVGTAG_START     SVG開始タグを出力する／しない
    #   :SVGTAG_END       SVG終了タグを出力する／しない
    #
    def set_mode(mode)
      mode = mode.to_s
      if mode.start_with?("NO_")
        mode.slice!(0, 3)
        @work_mode[mode.to_sym] = false
      else
        @work_mode[mode.to_sym] = true
      end
    end

    ##
    # (GraphBase)
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
      # calculate insufficiency parameters.
      top    ||= @at_plot_area[:y]
      right  ||= @width - @at_plot_area[:width] - @at_plot_area[:x]
      bottom ||= @height - @at_plot_area[:height] - @at_plot_area[:y]
      left   ||= @at_plot_area[:x]

      # set plot area parameters
      @at_plot_area[:x] = left
      @at_plot_area[:y] = top
      @at_plot_area[:width] = @width - left - right
      @at_plot_area[:height] = @height - top - bottom
      @at_plot_area[:width] = 0 if @at_plot_area[:width] < 0
      @at_plot_area[:height] = 0 if @at_plot_area[:height] < 0
    end

    ##
    # (GraphBase)
    # バッファーへ描画
    #
    #@example
    #  graph = AlGraph.new
    #  str = graph.draw_buffer()   # insted of draw()
    #
    def draw_buffer()
      @work_mode[:CONTENT_TYPE] = false if !@work_mode.key?(:CONTENT_TYPE)
      @work_mode[:XML_DECLARATION] = false if !@work_mode.key?(:XML_DECLARATION)

      output_bak = @output
      s = ""
      @output = StringIO.new(s)
      draw()
      @output = output_bak

      return s
    end

    ##
    # (GraphBase)
    # メインタイトルの追加
    #
    #@param [String] title_string    タイトル文字列
    #
    def add_main_title(title_string)
      set_margin(25, nil, nil, nil)
      @at_main_title = {:node_value=>title_string, :y=>20, :font_size=>16, :text_anchor=>'middle'}
    end

    ##
    # (GraphBase)
    # 凡例表示追加
    #
    #  自動追加されるので、たいていの場合、ユーザがこのメソッドを使うことはないかもしれない。
    #
    def add_legend()
      return if @at_legend

      right = @width - @at_plot_area[:width] - @at_plot_area[:x] + 70
      set_margin(nil, right, nil, nil)
      @at_legend = {:x=>@width - 60, :font_size=>10, :line_spacing=>4}
    end

    ##
    # (GraphBase)
    # 任意タグを追加
    #
    #@param [String] text    タグテキスト
    #
    def add_aux_tag(text)
      @aux_tags << text
    end

    ##
    # (GraphBase)
    # テキスト追加
    #
    #@param [Integer] x    X座標
    #@param [Integer] y    Y座標
    #@param [String] text  テキスト
    #
    #  addAuxTag()の簡易テキスト版。
    #  フォントサイズの指定などは、<tspan>要素を使える。
    #
    def add_text(x, y, text)
      @aux_tags << %!<text x="#{x}" y="#{y}">#{text}</text>\n!
    end

    private
    ##
    # (GraphBase)
    # 描画共通部１
    #
    def draw_common1()
      @work_mode[:CONTENT_TYPE] = true if !@work_mode.key?(:CONTENT_TYPE)
      @work_mode[:XML_DECLARATION] = true if !@work_mode.key?(:XML_DECLARATION)

      #
      # draw headers. (http header, xml header, and others)
      #
      if @work_mode[:CONTENT_TYPE] && defined?(Alone)
        Alone::add_http_header('Content-Type: image/svg+xml')
      end

      if @work_mode[:XML_DECLARATION]
        @output.printf(%!<?xml version="1.0" encoding="UTF-8" standalone="no" ?>\n!)
        @output.printf(%Q(<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n))
      end

      if @work_mode[:SVGTAG_START]
        @output.printf(%!<svg %swidth="%dpx" height="%dpx" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n\n!,
                       @id ? %!id="#{@id}" ! : "", @width, @height )
      end

      #
      # draw background and border.
      #
      @output.printf("<rect %s />\n", make_common_attribute_string(@at_graph_area))
      if @at_graph_area[:image]
        @output.printf(%!<image x="%d" y="%d" width="%d" height="%d" xlink:href="%s" />\n!, 0, 0, @width, @height, @at_graph_area[:image])
      end

      #
      # draw plot area.
      #
      @output.printf("<rect %s />\n", make_common_attribute_string(@at_plot_area))
      if @at_plot_area[:image]
        @output.printf(%!<image x="%d" y="%d" width="%d" height="%d" xlink:href="%s" />\n!, @at_plot_area[:x], @at_plot_area[:y],
        @at_plot_area[:width], @at_plot_area[:height], @at_plot_area[:image])
      end

    end

    ##
    # (GraphBase)
    # 描画共通部2
    #
    def draw_common2()
      #
      # draw main title.
      #
      if @at_main_title
        @at_main_title[:x] ||= @width / 2
        @output.printf("<text %s>%s</text>\n", make_common_attribute_string(@at_main_title), Alone::escape_html(@at_main_title[:node_value]))
      end

      #
      # auxiliary tags.
      #
      @aux_tags.each {|atag|
        @output.printf("%s", atag)
      }

      if @work_mode[:SVGTAG_END]
        @output.printf( "\n</svg>\n" )
      end
    end

  end  # /GraphBase

end  # /AlGraph
