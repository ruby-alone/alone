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
# ログイン、ログアウトを実行するためのコントローラ

require 'al_login_main'

##
# ログインクラスサンプル
#
#@note
# AlLoginクラスを継承し、confirm()メソッドを作成して、認証作業を行います。
# 認証結果は、booleanで返します。
#
class MyLogin < AlLogin
  USERLIST = { 'user1'=>'pass2',
               'user2'=>'pass1',
  }

  def confirm()
    return USERLIST[ @values[:user_id] ] == @values[:password]
  end
end


class AlController

  #
  # ログイン
  #
  def action_login()
    login = MyLogin.new()       # 独自テンプレートを引数にできます。
    if login.login()
      puts "このメッセージは、直接、当コントローラにアクセスされ、ログインが成功した時にのみ表示されます。"
      puts "実際のアプリケーションでは、トップページやメニューページへのリダイレクトにするとよいでしょう。"
      puts '例：Alone.redirect_to( Alone.make_uri(ctrl:"",action:"") )'

    else
      # 初回アクセス時、及びログインが成功しなかった場合の処理を
      # ここに書くことができますが、既に表示も終わった後なので、
      # 有用性は限られるでしょう。
    end
  end
  alias action_index action_login


  #
  # ログアウト
  #
  def action_logout()
    AlLogin.logout()
    AlTemplate.run( './al_logout.rhtml' )
  end

end
