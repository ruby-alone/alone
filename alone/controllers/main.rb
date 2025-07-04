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
#@brief
# これは、Aloneサンプルアプリケーションの為の、簡易ランチャーです。
# ディレクトリリストを表示し、クリックして実行できるようにします。
# main.rb内に #@TITLE 行があれば、それ以降のコメントをメニューとして表示します。

require 'al_template'

TEMPLATE_STR = %Q(
<%= header_section %>
  <title>Aloneサンプル一覧</title>

<%= body_section %>
  <div class="al-page-header">Aloneサンプル一覧</div>
  <p>この画面は、コントローラ指定が無い場合(*1) に動作するデフォルトのコントローラ(*2) が出力しています。
    <pre>  <%= @thisfilename %></pre>
    <div style="margin-left: 4em; font-size: 80%;">
      *1 URIに ctrl=xxx が指定されない場合<br>
      *2 AL_CTRL_DIR に指定したパスの main.rb<br>
    </div>
  </p>

  <ol>
    <% @app_list.each do |m| %>
    <li><%= m %></li>
    <% end %>
  </ol>

<%= footer_section %>
)

class SimpleMenuController < AlController
  def action_index
    @app_list = []
    @thisfilename = __FILE__

    Dir.glob("*").sort.each do |dirname|
      next if ! FileTest.directory?( dirname )

      # open README file
      title = nil
      begin
        File.open( File.join( dirname, "README" )) {|file|
          title = file.gets().chomp
          title = nil  if title == ".hidden"
        }
      rescue
        title = dirname
      end
      next if !title

      # make link strings.
      uri = Alone::make_uri( :ctrl => dirname )
      @app_list << "<a href=\"#{uri}\">#{title}</a>"
    end

    AlTemplate.run_str( TEMPLATE_STR )
  end

end
