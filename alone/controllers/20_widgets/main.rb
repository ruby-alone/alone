#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# alone : application framework for embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2022 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require 'alone'

class WidgetsController < AlController

  #
  # constructor
  #
  def initialize()
    @form = AlForm.new(
      # テキスト系
      AlText.new("text1", label:"テキスト", value:"SampleText" ),
      AlHidden.new("hidden1", label:"ヒドゥンテキスト", value:"Hidden" ),
      AlPassword.new("passowrd1", label:"パスワード", value:"PassText" ),
      AlTextArea.new("textarea1", label:"テキストエリア",
        value:"TextArea\n改行含むテキストが、\n入力できます" ),

      # セレクター系
      AlCheckboxes.new("check1", label:"チェックボックス",
        options:{c1:"チェック１", c2:"チェック２", c3:"チェック３"},
        value:[:c1, :c2] ),
      AlRadios.new("radio1", label:"ラジオボタン",
        options:{r1:"ラジオ１", r2:"ラジオ２", r3:"ラジオ３"},
        value: :r3 ),
      AlOptions.new("option1", label:"プルダウンメニュー",
        options:{o1:"オプション１", o2:"オプション２", o3:"オプション３"},
        value: :o3 ),

      # 数字
      AlInteger.new("integer1", label:"整数", value:12345 ),
      AlFloat.new("float1", label:"実数", value:2.7 ),

      # 日時
      AlDate.new("date1", label:"日付", value:Time.now ),
      AlTime.new("time1", label:"時刻", value:Time.now ),
      AlTimestamp.new("timestamp1", label:"日時", value:Time.now ),

      # メールアドレス
      AlMail.new("mail1", label:"メールアドレス", value:"nobody@example.com" ),

      # ボタン
      AlButton.new("button1", value:"汎用ボタン" ),
      AlSubmit.new("submit1", value:"決定" ),
    )
    @form.action = Alone::make_uri( action:'posted' )
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
