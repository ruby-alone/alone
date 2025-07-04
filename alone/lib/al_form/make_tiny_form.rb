#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# alone : application framework for small embedded systems.
#               Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#
# This file is destributed under BSD License. Please read the COPYRIGHT file.
#
# フォームマネージャ 簡易フォーム生成


class AlForm

  ##
  # 簡易フォームの自動生成
  #
  #@param [Hash] appendix_tag   htmlタグへ追加するアトリビュートを指定
  #@return [String]     生成したHTML
  #@note
  # tableタグを使って、位置をそろえている。
  #
  def make_tiny_form( appendix_tag = {} )
    r = %Q(<form method="#{@method}" action="#{Alone::escape_html(@action)}")
    @tag_attr.each {|k,v|
      r << (v ? %Q( #{k}="#{Alone::escape_html(v)}") : " #{k}")
    }
    appendix_tag.each {|k,v|
      r << (v ? %Q( #{k}="#{Alone::escape_html(v)}") : " #{k}")
    }
    r << ">\n" << make_tiny_form_main() << "</form>\n"
    return r
  end


  ##
  # 簡易フォームの自動生成　メインメソッド
  #
  #@note
  # TODO: アプリケーションからこのメソッドが独自によばれることがなさそうなら
  #       make_tiny_form()へ吸収合併を考えること。
  #
  def make_tiny_form_main()
    r = %Q(<table class="al-form-table">\n)
    hidden = ""
    @widgets.each do |k,w|
      if w.hidden
        hidden << w.make_tag()
        next
      end

      r << %Q(  <tr class="#{w.name}">\n)
      if @validation_messages[ k ]
        r << %Q(    <td class="al-form-label-error">#{w.label}\n)
      else
        r << %Q(    <td class="al-form-label">#{w.label}\n)
      end
      r << %Q(    <td class="al-form-value">#{w.make_tag()}\n  </tr>\n)
    end
    r << "</table>\n"
    if ! hidden.empty?
      r << "<div>#{hidden}</div>\n"
    end

    return r
  end
end
