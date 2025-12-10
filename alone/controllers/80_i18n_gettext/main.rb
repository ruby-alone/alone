#
# i18n test
#
# i18n target source
#  * controller or model ruby code (.rb)
#  * HTML template (.rhtml)
#  * JavaScript (.js)
#

require 'al_template'

class I18nTestController < AlController

  def initialize
    # 将来不要にする変更の予定あり
    @locale = defined?(AL_DEFAULT_LOCALE) ? AL_DEFAULT_LOCALE : ""
  end

  #
  # デフォルトアクション
  #
  def action_index()
    # コントローラ内翻訳（モデル内も同じ）
    @my_message = _("messages in controller.")

    AlTemplate.run("index.rhtml")
  end
end
