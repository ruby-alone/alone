#!/usr/bin/env ruby
# alone : application framework for embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2025 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# フォームを使ったアプリケーションサンプル
#
# 画面遷移
#  [入力画面] → [確認画面] ---------→ [完了画面]
#     ↑            |      (commit)
#      -------------
#             (cancel)
#

require 'alone'

class FormController1 < AlController

  ##
  # constructor
  #
  def initialize()
    @form = AlForm.new(
      AlText.new( "text1", :label=>"名前", :value=>"ボズ・スキャッグス" ),
      AlRadios.new( "radio1", :label=>"性別",
        :options=>{ :r1=>"男性", :r2=>"女性", :r3=>"不明" }, :value=>"r1" ),
      AlCheckboxes.new( "check1", :label=>"趣味",
        :options=>{ :c1=>"音楽", :c2=>"スポーツ", :c3=>"読書" },
        :value=>[:c1], :required=>true ),
      AlSubmit.new( "submit1", :value=>"決定",
        :tag_attr=> {:style=>"float: right;"} )
    )
    @form.action = Alone::make_uri( :action=>'confirm' )
  end


  ##
  # デフォルトアクション
  #
  #@note
  # 念のためセッション変数を全て消去してから、デフォルト画面を表示
  #
  def action_index()
    session.delete_all()
    AlTemplate.run("./index.rhtml")
  end


  ##
  # 確認画面
  #
  #@note
  # フォームから送られた値を確認し、
  # OKならセッションに保存した上で、確認画面を表示する。
  # NGならデフォルトフォームに戻す。
  #
  def action_confirm()
    if @form.validate()
      session[:values] = @form.values
      AlTemplate.run("./confirm.rhtml")
    else
      AlTemplate.run("./index.rhtml")
    end
  end


  ##
  # 確認画面で、「はい」を選ばれた場合の動作
  #
  #@note
  # セッションから変数を戻してフォームにセットし直し、完了画面を表示する。
  #
  def action_commit()
    @form.set_values( session[:values] )
    AlTemplate.run("./commit.rhtml")
  end


  ##
  # 確認画面で、「いいえ」を選ばれた場合の動作
  #
  #@note
  # セッションから変数を戻した上でフォームにセットし直し、入力画面に戻す。
  #
  def action_cancel()
    @form.set_values( session[:values] )
    AlTemplate.run("./index.rhtml")
    session.delete( :values )
  end

end
