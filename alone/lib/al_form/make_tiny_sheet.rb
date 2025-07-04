#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# alone : application framework for small embedded systems.
#               Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#
# This file is destributed under BSD License. Please read the COPYRIGHT file.
#
# フォームマネージャ 簡易内容表示


class AlForm

  ##
  # 簡易内容表示
  #
  #@return [String]     生成したHTML
  #@note
  # tableタグを使って、位置をそろえている。
  #
  def make_tiny_sheet()
    r = %Q(<table class="al-sheet-table">\n)
    @widgets.each do |k,w|
      next if w.is_a?( AlButton ) || w.hidden

      r << %Q(  <tr class="#{w.name}">\n)
      r << %Q(    <td class="al-sheet-label">#{w.label}\n)
      r << %Q(    <td class="al-sheet-value">#{w.make_value()}\n  </tr>\n)
    end
    r << "</table>\n"

    return r
  end
end
