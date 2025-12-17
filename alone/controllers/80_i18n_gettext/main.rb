#!/usr/bin/env ruby
# alone : application framework for embedded systems.
#   Copyright (c) 2018-2025 Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
#
# i18n test
#
# i18n target source
#  * controller or model ruby code (.rb)
#  * HTML template (.rhtml)
#  * JavaScript (.js)
#

require 'al_template'
require "al_form"

class I18nTestController < AlController

  def initialize
    #session.delete_all()

    if AlSession[:locale]
      @locale = AlSession[:locale]
    elsif defined?(AL_DEFAULT_LOCALE)
      @locale = AL_DEFAULT_LOCALE
    else
      @locale = ""
    end
    set_locale( @locale )

    @locale_sel = AlOptions.new("locale",
        :options=>{none:"----", en_US:"en_US", ja_JP:"ja_JP", de_DE:"de_DE"},
        :value=>@locale )
  end

  #
  # デフォルトアクション
  #
  def action_index()
    # コントローラ内翻訳（モデル内も同じ）
    @my_message = _("messages in controller.")

    AlTemplate.run("./index.rhtml")
  end

  #
  # ロケール変更
  #
  def action_change_locale()
    @form = AlForm.new( @locale_sel );
    if @form.validate()
      @locale = (@form.values[:locale] == "none") ? "" : @form.values[:locale]
      AlSession[:locale] = @locale
      set_locale( @locale )
    end

    action_index()
  end
end
