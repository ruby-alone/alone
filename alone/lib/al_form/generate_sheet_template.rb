#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# alone : application framework for small embedded systems.
#               Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#
# This file is destributed under BSD License. Please read the COPYRIGHT file.
#
# フォームマネージャ 簡易内容表示テンプレートの生成


class AlForm

  ##
  # 簡易内容表示テンプレートの生成
  # AlTemplateの使用を前提とした単票形式表示のテンプレートを生成する。
  #
  #@param  arg          引数ハッシュ
  #@option arg [Boolean] :use_table            テーブルタグを利用した整形
  #
  def generate_sheet_template( arg = {} )
    flags = { :use_table=>true }
    flags.merge!( arg )

    r = "<%= header_section %>\n<title></title>\n\n"
    r << "<%= body_section %>\n\n"

    if flags[:use_table]
      r << %Q(<table class="al-sheet-table">\n)
      @widgets.each do |k,w|
        next if w.is_a?( AlButton )

        r << %Q(  <tr class="#{w.name}">\n)
        r << %Q(    <td class="al-sheet-label">#{w.label}\n)
        r << %Q(    <td class="al-sheet-value"><%= @form.make_value(:#{w.name}) %>\n)
        r << %Q(  </tr>\n\n)
      end
      r << "</table>\n"

    else
      @widgets.each do |k,w|
        next if w.is_a?( AlButton )

        r << %Q(  <div class="#{w.name}">\n)
        r << %Q(    <span class="al-sheet-label">#{w.label}</span>\n)
        r << %Q(    <span class="al-sheet-value"><%= form.make_value(:#{w.name} ) %></span>\n)
        r << %Q(  </div>\n\n)
      end
    end

    r << "\n<%= footer_section %>"
    return r
  end

end
