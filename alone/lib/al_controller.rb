#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2025 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# Controller
#

require 'al_main'
require 'al_session'


##
# Aloneコントローラクラス
#
# コントローラ名、ステート名、アクション名、この３つのパラメータにより、
# 全体を駆動する。
# コントローラは、パラメータ ctrl= で、アクションは、action= で指定される。
# ただし、これらパラメータのパースはメインモジュールにて行い、ここでは、
# その値のエイリアスをもらっている。
# 併せて、(ちょっとした工夫により）コントローラごとに名前空間分離した
# 専用セッション変数を持たせる機能もインプリメントしてある。
#
class AlController

  # コントローラ名（メインモジュールの値のエイリアス）
  CTRL = Alone::ctrl

  # フレームワーク側で生成するクラスを保存
  @@suitable_class = self


  ##
  # getter suitable_class
  #
  def self.suitable_class
    return @@suitable_class
  end


  ##
  # ユーザプログラムで継承された場合にそれを保存する
  #
  def self.inherited( subclass )
    @@suitable_class = subclass
  end


  ##
  # コントローラローカルのセッション変数の動作定義
  #
  class AlControllerSession
    ##
    # 変数の保存
    #
    #@param [Symbol] k キー
    #@param [Object] v 値
    #
    def self.[]=( k, v )
      AlSession["AL_#{CTRL}_#{k}"] = v
    end

    ##
    # 変数の取得
    #
    #@param  [Symbol] k キー
    #@return [Object] 値
    #
    def self.[]( k )
      return AlSession["AL_#{CTRL}_#{k}"]
    end

    ##
    # 変数の消去
    #
    #@param  [Symbol] k キー
    #
    def self.delete( k )
      AlSession::delete( "AL_#{CTRL}_#{k}" )
    end

    ##
    # 変数の全消去
    #
    def self.delete_all()
      prefix = "AL_#{CTRL}_"
      AlSession::keys().each do |k|
        AlSession::delete( k )  if k.to_s.start_with?( prefix )
      end
    end
  end


  #@return [String] 動作選出されたメソッド名 (TODO: 要る？)
  attr_reader :respond_to


  ##
  # getter: session
  #
  #@return [AlControllerSession] コントローラローカルセッションの操作オブジェクト
  #
  def session()
    return AlControllerSession
  end


  ##
  # ログ出力
  #
  #@see Alone.log()
  #
  def log( *args )
    Alone.log( *args )
  end


  ##
  # リンク用のURIを生成する
  #
  def make_uri( arg = {} )
    Alone.make_uri( arg )
  end


  ##
  # アプリケーション実行開始（内部メソッド）
  #
  #@note
  # 各パラメータによりユーザコードを選択し、実行する。
  #
  def _exec()
  # アクション名（メインモジュールの値のエイリアス）
    action = Alone::action
    if action.empty?
      action << "index" # 同じオブジェクトを使うために << を使う。
    end

    @respond_to = "action_#{action}"
    if respond_to?( @respond_to )
      return __send__( @respond_to )
    end

    # 実行すべきメソッドが見つからない場合
    @respond_to = ""
    no_method_error()
  end


  ##
  # メソッドエラーの場合のエラーハンドラ
  #
  #@note
  # エラー表示などしたければ、当メソッドをオーバライドする。
  #
  def no_method_error()
    Alone::add_http_header( "Status: 404 Not Found" )
    raise "No action defined. CTRL: #{CTRL}, ACTION: #{Alone::action}"
  end


  ##
  # デバグ用：各パラメータの表示用文字列を返す
  #
  #@return [String]  デバグ用文字列
  #
  def self.debug_dump()
    r = "CTRL: #{CTRL}, ACTION: #{Alone::action}, RESPOND TO: #{$AlController.respond_to}\n"
    r << "SESSION VAR:\n"
    prefix = "AL_#{CTRL}_"
    AlSession::keys().each do |k|
      if k.to_s.start_with?( prefix )
        r << "  #{k.to_s[prefix.size,100]}: #{AlSession[k]}\n"
      end
    end
    return r
  end


  ##
  # ロケールの設定
  #
  #@param  [String]   locale_string  ロケール文字列。e.g. "ja_JP"
  #@return [String]   設定されたロケール文字列
  #
  def init_locale( locale_string = nil )
    if locale_string
      @al_locale = locale_string.to_s
      AlSession[:al_locale] = @al_locale

    elsif AlSession[:al_locale]
      @al_locale = AlSession[:al_locale]

    else
      @al_locale = ""
      return @al_locale
    end

    set_locale( @al_locale )
    return @al_locale
  end


  ##
  # 翻訳ファイルのパスを返す
  #
  #@return [String]  翻訳ファイルのパス
  #@example
  #  htmlテンプレート中で以下のように使う
  #  <script src="<%=s gettext_message_uri() %>"></script>
  #
  def gettext_message_uri()
    return "locale/#{@al_locale}/messages.js"
  end

end


##
# コントローラローカルセッションを他のクラスでも使うためのモジュール
#
module AlControllerSession
  ##
  # getter: session
  #
  #@return [AlControllerSession] コントローラローカルセッションの操作オブジェクト
  #
  def session()
    return AlController::AlControllerSession
  end
end


##
# 実行開始
#
if ! defined? AL_CTRL_NOSTART
  begin
    # コントローラを初期化し、必要なユーザコードを読み込む
    Dir.chdir( File.join( AL_CTRL_DIR, AlController::CTRL ) )
    require './main.rb'

  rescue Exception => ex
    Alone::handle_error( ex )
  end

  # ユーザコードの実行
  Alone::main() {
    $AlController = AlController.suitable_class.allocate
    $AlController.__send__( :initialize )
    $AlController._exec()
  }
end
