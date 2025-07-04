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

# ログインが必要なコントローラへ、
#   require "al_login"
# を記述します。
# アプリケーション全体でログインが必要な場合は、エントリポイントへ
# requireを記述する方が良いでしょう。
#
require "al_login"
require "al_template"


class AlController

  #
  # デフォルトアクションの定義
  #  (note)
  #  ログインが成功してから実行されます。
  #
  def action_index()
    AlTemplate.run( 'index.rhtml' )
  end

end
