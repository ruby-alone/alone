#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# alone : application framework for small embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2022 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the COPYRIGHT file.
#

require 'alone'

class WidgetsController < AlController

  #
  # constructor
  #
  def initialize()
    @form = AlForm.new(
      AlText.new("text1", label:'プレースホルダ (placeholder="...")',
        tag_attr:{placeholder:"入力値案内文"} ),

      AlText.new("text2", label:"オートフォーカス (autofocus)",
        tag_attr:{autofocus:nil}),
      # autofucus:true にしたい所だが、アトリビュート値"true"を
      # 使う可能性を潰すのでnilでがまんする。

      AlText.new("text3", label:"必須属性 (required)",
                 :required=>true, tag_attr:{required:nil} ),

      # 最大文字数指定
      AlText.new("text4", label:"最大文字数5 (maxlength=5)",
                 max:5, tag_attr:{maxlength:5} ),

      # 数字
      AlInteger.new("integer1", tag_type:"number", label:'数値 (type="number")' ),
      AlInteger.new("integer2", tag_type:"number", label:"最小最大 (min=10, max=100)",
                    value: 10, min:10, max:100, tag_attr:{min:10, max:100} ),
      AlFloat.new("float1", tag_type:"number", label:"ステップ指定 (step=0.1)",
                  value: 0, tag_attr:{step:0.1} ),

      # 日時
      AlDate.new("date1", tag_type:"date", label:'日付 (type="date")', value:Time.now ),
      AlTime.new("time1", tag_type:"time", label:'時刻 (type="time")', value:Time.now ),
      AlTimestamp.new("timestamp1", tag_type:"datetime-local", label:'日時 (type="datetime-local")', value:Time.now ),

      # メールアドレス
      AlMail.new("mail1", tag_type:"email", label:'メールアドレス (type="email")' ),

      # スライダー
      AlInteger.new("slider1", tag_type:"range", label:'スライダー (type="range")',
                    value: 10, min:0, max:100, tag_attr:{min:0, max:100} ),

      # カラーピッカー
      AlText.new("color1", tag_type:"color", label:'カラーピッカー (type="color")'),

      # 決定ボタン
      AlSubmit.new("submit1", value:"決定" ),
    )
    @form.action = Alone::make_uri( action:"posted" )
  end


  #
  # デフォルトアクション
  #
  def action_index()
    AlTemplate.run( 'index.rhtml' )
  end


  #
  # フォームデータがPOSTされた時のアクション
  #
  def action_posted()
    if @form.validate()
      AlTemplate.run( 'posted.rhtml' )
    else
      AlTemplate.run( 'index.rhtml' )
    end
  end
end
