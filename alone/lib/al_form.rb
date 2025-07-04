#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# alone : application framework for small embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2022 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the COPYRIGHT file.
#
# フォームマネージャ
#

##
# フォームクラス
#
# htmlフォームからの送信を受け取り、ユーザーアプリケーションへ渡す。
#
class AlForm

  #[Hash] GETリクエストを解析してHash化した値のキャッシュ
  @@request_get = {}

  #[Hash] POSTリクエストを解析してHash化した値のキャッシュ
  @@request_post = {}

  #[Boolean] リクエストサイズ過大エラーフラグ
  @@flag_request_oversize = false

  # :filter用、前後空文字削除フィルター
  FILTER_STRIP = lambda { |s| s.strip!; s }


  ##
  # GETリクエストのキャッシュへの取り込み
  #
  def self.prefetch_request_get()
    return if ! @@request_get.empty?
    return if ! ENV["QUERY_STRING"]

    @@request_get = parse_urlencoded( ENV["QUERY_STRING"] )
  end


  ##
  # POSTリクエストのキャッシュへの取り込み
  #
  def self.prefetch_request_post()
    return if ! @@request_post.empty?

    # check request size
    if ENV["CONTENT_LENGTH"].to_i > AL_FORM_MAX_CONTENT_LENGTH
      @@flag_request_oversize = true
    end

    # proc multipart request data.
    if ENV["CONTENT_TYPE"] && ENV["CONTENT_TYPE"].start_with?("multipart/form-data")
      require "al_form/multipart"
      fetch_request_multipart()
      return
    end

    # read post data
    if ENV["CONTENT_LENGTH"]
      txt = $stdin.read( ENV["CONTENT_LENGTH"].to_i )
    else
      txt = $stdin.read()
    end

    if ENV["CONTENT_TYPE"] && ENV["CONTENT_TYPE"].start_with?("application/x-www-form-urlencoded")
      @@request_post = parse_urlencoded( txt )
    else
      @@request_post[""] = txt
    end
  end


  ##
  # getter / request_get
  #
  #@return [Hash]       GETリクエストのキャッシュ
  #@note 渡された生データが入っているので、通常は使わない。
  #
  def self.request_get()
    return @@request_get
  end


  ##
  # getter / request_post
  #
  #@return [Hash]       POSTリクエストのキャッシュ
  #@note 渡された生データが入っているので、通常は使わない。
  #
  def self.request_post()
    return @@request_post
  end


  ##
  # 単一パラメータの取得／使い捨てミニフォーム機能
  #
  #@param [AlWidget] w          取得するパラメータを表すウィジェット
  #@return [Object]             取得値。データタイプは、Widgetによって変わる。
  #@return [NilClass]           取得できなかった（エラー）の場合。
  #@example id = AlForm.get_parameter( AlText.new( 'id', :validator=>/^\d+$/ ) )
  #
  def self.get_parameter( w )
    case ENV["REQUEST_METHOD"]
    when "GET"
      AlForm.prefetch_request_get()
      value = @@request_get[w.name.to_sym]
    when "POST"
      AlForm.prefetch_request_post()
      value = @@request_post[w.name.to_sym]
    else
      raise "method error. need GET or POST."
    end

    if value
      # GET/POSTされている。フィルタをかけてウィジェットに渡した結果を返す。
      w.set_value( apply_filter( w.filter, value ))
      return w.validate() ? w.value : nil
    else
      # ウィジェットの初期値を返す。
      return w.value
    end
  end


  #@return [Hash] このインスタンスが保持するウィジェット。キーがウィジェット名のシンボル、値がウィジェットのインスタンス
  attr_reader :widgets

  #@return [Hash] バリデーションを通過したリクエストの値
  attr_reader :values

  #@return [Hash] バリデーションメッセージ。キーがウィジェット名のシンボル、値がメッセージ文字列
  attr_reader :validation_messages

  #@return [String] HTMLフォームのmethodアトリビュート "GET" or "POST"
  attr_accessor :method

  #@return [String] HTMLフォームのactionアトリビュート
  attr_accessor :action

  #@return [Hash] HTMLタグ生成時の追加アトリビュート
  attr_accessor :tag_attr

  #@return [Boolean] 値のセットが終わっているかのフラグ（バリデーション前）
  attr_accessor :flag_setvalue_done


  ##
  # (AlForm) constructor
  #
  #@param [Array] widgets       ウィジェットの配列
  #
  def initialize( *widgets )
    @widgets = {}
    @values = {}
    @validation_messages = {}
    @validation_messages_user_count = 0
    @method = "POST"
    @action = Alone::request_uri()
    @tag_attr = {}
    @flag_setvalue_done = false

    set_widgets( widgets )
  end


  ##
  # コントローラ使用時に、フォームでmethod="GET"を使う
  #
  #@option arg [String] :ctrl           コントローラ名
  #@option arg [String] :action         アクション名
  #@note form method="GET" と、AlControllerの仕組みを共存させるためのメソッド。
  #
  def use_get_method( arg = {} )
    @widgets[:ctrl] = AlHidden.new("ctrl", :value=>(arg[:ctrl] || Alone::ctrl));
    @widgets[:action] = AlHidden.new("action", :value=>(arg[:action] || Alone::action));
    @method = "GET"
  end


  ##
  # ウィジェットのセット
  #
  #@param [Array] widgets       ウィジェットの配列
  #
  def set_widgets( *widgets )
    raise "Parameter type error. need Array."  if widgets.class != Array
    widgets.flatten.each do |w|
      @widgets[ w.name.to_sym ] = w
    end
  end
  alias widgets= set_widgets


  ##
  # ウィジェット追加
  #
  #@param [AlWidget]  widget    ウィジェット
  #
  def add_widget( widget )
    @widgets[ widget.name.to_sym ] = widget
  end


  ##
  # ウィジェット削除
  #
  #@param [String,Symbol] name  ウィジェット識別名
  #
  def delete_widget( name )
    @widgets.delete( name.to_sym )
    @values.delete( name.to_sym )
  end


  ##
  # ウィジェットの取得
  #
  #@param [String,Symbol] name  ウィジェット識別名
  #@return [AlWidget]           ウィジェット
  #
  def get_widget( name )
    return @widgets[ name.to_sym ]
  end


  ##
  # 値のセット
  #
  #@param [String,Symbol] name  ウィジェット識別名
  #@param [String,Array]  value セットする値
  #@note 受け付けるvalueは、ウィジェットの種類によって変わる。
  #      詳しくは、各ウィジェットを参照。
  #
  def set_value( name, value )
    k = name.to_sym
    @widgets[k].set_value( value )
    @values[k] = @widgets[k].value      # valueは、Widgetごとの都合による加工がされているかもしれない
  end
  alias []= set_value


  ##
  # 値の一括セット
  #
  #@param [Hash,NilClass] values        セットする値
  #@note nilを与えられた場合は、何も行わない。
  #      それ以外の場合は、fetch_request()を呼び出したのと同様、
  #      validate()の値自動取得が働かなくなるので注意する。
  #
  def set_values( values )
    return if ! values
    raise "set_values() needs Hash parameter." if values.class != Hash

    values.each do |k,v|
      k = k.to_sym
      next  if ! @widgets[k]
      @widgets[k].set_value( v )
      @values[k] = @widgets[k].value      # valueは、Widgetごとの都合による加工がされているかもしれない
    end
    @flag_setvalue_done = true
  end
  alias values= set_values


  ##
  # 値取得
  #
  #@param [String,Symbol] name  ウィジェット識別名
  #@return [Object]             値
  #@note バリデーション後の値を取得する。
  #      値として何が返るかは、ウィジェットの種類によって変わるので、
  #      詳しくは各ウィジェットを参照。
  #
  def get_value( name )
    return @values[name.to_sym]
  end
  alias [] get_value


  ##
  # バリデーション前の値取得
  #
  #@param [String,Symbol] name  ウィジェット識別名
  #@return [Object]             値
  #@note alias - は、テンプレートで使われることを想定して定義した。
  #      プログラム中では、使わない方が良いのではないか。
  #
  def get_tainted_value( name )
    return (w = @widgets[ name.to_sym ]) ? w.value : nil
  end
  alias - get_tainted_value


  ##
  # メッセージの追加
  #
  #@param [String]  message     メッセージ
  #@note ユーザプログラムから、任意のメッセージをセットできる。
  #      バリデーション validate() を行う前にクリアされるので、注意する。
  #
  def add_message( message )
    @validation_messages["al_user#{@validation_messages_user_count}"] = message
    @validation_messages_user_count += 1
  end


  ##
  # html形式でメッセージの取得
  #
  #@return [String]     html形式でメッセージを返す
  #
  def get_messages_by_html()
    r = ""
    @validation_messages.each do |k,v|
      r << Alone::escape_html_br(v) << "<br>\n"
    end
    return r
  end


  ##
  # GET/POSTリクエストの取り込み
  #
  #@param [String] method       メソッド "GET" or "POST"
  #@return [Boolean]            成否
  #@return [String]             POSTされたデータ(see note)
  #
  #@note
  # POSTされたデータのタイプが application/x-www-form-urlencoded もしくは、
  # multipart/form-data ではない場合は、POSTデータそのものを返す。
  #
  def fetch_request( method = nil )
    #
    # リクエストを取得し、@@request_XXXにキャッシュする。
    #
    case method || ENV["REQUEST_METHOD"]
    when "GET"
      AlForm.prefetch_request_get()
      req = @@request_get

    when "POST"
      return false if ENV["REQUEST_METHOD"] != "POST"
      AlForm.prefetch_request_post()
      req = @@request_post

    else
      raise "method error. need GET or POST."
    end

    #
    # リクエストが正当なものか確認
    #
    if @@flag_request_oversize
      add_message("サイズが大きすぎます。")
      return false
    end
    return req[""]  if req[""]  # return posted string. e.g. JSON.

    flag_exist = false
    @widgets.each {|k,w|
      next if k == :ctrl || k == :action
      break if (flag_exist = req.has_key?(k))
    }
    return false  if !flag_exist

    #
    # 各ウィジェットに、値を設定
    #
    @widgets.each { |k,w|
      w.set_value( AlForm::apply_filter( w.filter, req[k] ? req[k] : "" ))
    }

    @flag_setvalue_done = true
    return true
  end


  ##
  # バリデーション
  #
  #@param [Array] names         バリデーションするウィジェット名の配列
  #@return [Boolean]            成否
  #@note 引数を与えなければ、すべてのウィジェットについてバリデーションを実施する
  #      バリデーションが成功して、はじめて @values に使える値が用意される。
  #
  def validate( names = nil )
    @validation_messages.clear

    #
    # リクエストの取得がまだ行われていないなら、自動で取得する
    #
    if ! @flag_setvalue_done
      return false  if ! fetch_request()
    end

    case names
    when NilClass
      #
      # すべてのウィジェットについてバリデーションを実施
      #
      @widgets.each do |k,w|
        next  if w.class == AlSubmit    # valueをとりたくないのでskip
        if w.validate()
          @values[k] = w.value
        else
          @validation_messages[k] = w.message
        end
      end

    when Array
      #
      # 選択的にバリデーションを実施
      #
      names.each do |k|
        k = k.to_sym
        w = @widgets[k]
        raise "Not found widget '#{k}'." if ! w
        next  if w.class == AlSubmit    # valueをとりたくないのでskip
        if w.validate()
          @values[k] = w.value
        else
          @validation_messages[k] = w.message
        end
      end

    when String, Symbol
      #
      # 一つだけバリデーションを実施
      #
      k = names.to_sym
      w = @widgets[k]
      if w.validate()
        @values[k] = w.value
      else
        @validation_messages[k] = w.message
      end

    else
      raise 'validate() needs an array, string or symbol argument.'

    end

    return @validation_messages.empty?
  end


  ##
  # (AlForm) HTMLタグの生成
  #
  #@param [String,Symbol] name  ウィジェット識別名
  #@param [Hash] appendix_tag   htmlタグへ追加するアトリビュートを指定
  #@return [String]             htmlタグ
  #@note 指定された名前を持つウィジェットのタグを生成し返す。
  #@example <%= form.make_tag( :text1 ) %>
  #
  def make_tag( name, appendix_tag = {} )
    widget = @widgets[ name.to_sym ]
    raise %Q(No widget defined, named "#{name}".)  if ! widget

    return widget.make_tag( appendix_tag )
  end


  ##
  # (AlForm) HTML値の生成
  #
  #@param [String,Symbol] name  ウィジェット識別名
  #@return [String]     html文字列
  #@note make_tag()との対称性をもたせるために存在する。
  #
  def make_value( name )
    widget = @widgets[ name.to_sym ]
    raise %Q(No widget defined, named "#{name}".)  if ! widget

    return widget.make_value()
  end


  ##
  # inputタグ中の checked 属性生成
  #
  #@param [String,Symbol] name  ウィジェット識別名
  #@param [String,Symbol] value inputタグのvalue="" と同じ値を指定する。
  #@note チェックボックス、または、ラジオボタンの、checked属性を生成する。
  #      htmlをべたに書く時にのみ使用する。
  #@example <input name="radio1" type="radio" value="r1" <%= form.checked( :radio1, "r1" ) %> >
  #
  def checked( name, value )
    widget = @widgets[ name.to_sym ]
    case widget
    when AlCheckboxes
      return (widget.value.include?( value.to_sym ) || widget.value.include?( value.to_s )) ? "checked": ""

    when AlOptions
      return (widget.value && widget.value.to_sym == value.to_sym) ? "selected": ""

    when AlRadios
      return (widget.value && widget.value.to_sym == value.to_sym) ? "checked": ""

    else
      raise "Object not match. needs AlCheckboxes, AlOptions or AlRadios"
    end
  end
  alias selected checked


  #
  # ダイナミックローディング
  #

  # ダイナミックローディングメソッド名テーブル
  METHOD_LIST = {
    :make_tiny_form=>"al_form/make_tiny_form",
    :make_tiny_form_main=>"al_form/make_tiny_form",
    :make_tiny_sheet=>"al_form/make_tiny_sheet",
    :generate_form_template=>"al_form/generate_form_template",
    :generate_sheet_template=>"al_form/generate_sheet_template",
    :generate_list_template=>"al_form/generate_list_template",
    :generate_sql_table=>"al_form/generate_sql_table",
  }

  ##
  # ダイナミックローディング用フック
  #
  def method_missing( name, *args )
    if METHOD_LIST[ name ]
      require METHOD_LIST[ name ]
      __send__( name, *args )
    else
      raise NoMethodError, "undefined method `#{name}' for AlForm"
    end
  end


  private
  ##
  # URLエンコードされたリクエストの解析
  #
  #@param [String] query_string 解析するURL
  #@return [Hash]               解析結果のハッシュ
  #
  def self.parse_urlencoded( query_string )
    req = {}
    query_string.split('&').each do |a|
      (k,v) = a.split( '=', 2 )

      k = k.to_sym
      v = Alone::decode_uri_component( v.tr( '+', ' ' ) )  if v

      case req[k]
      when NilClass
        req[k] = v

      when String
        req[k] = [ req[k], v ]

      when Array
        req[k] << v
      end
    end

    return req
  end


  ##
  # フィルターの適用
  #@param [NilClass,String,Proc,Method,Array] filter フィルターまたはフィルターの配列
  #@return [Object] フィルター適用後の値
  #
  def self.apply_filter( filter, value )
    case filter
    when NilClass
      return value
    when String
      eval( filter )
      return value
    when Proc, Method
      return filter.call( value )
    when Array
      filter.each { |f| value = apply_filter( f, value ) }
      return value
    else
      raise "Illegal filter class. '#{filter.class}'"
    end
  end

end     # /AlForm



##
# ウィジェット　スーパークラス
#
class AlWidget

  #@return [Symbol] 識別名
  attr_reader :name

  #@return [String] ラベル
  attr_accessor :label

  #@return [Object] 入力値または初期値
  attr_accessor :value

  #@return [String,Nil] make_valueで使用する変換フォーマット文字列
  attr_accessor :value_format

  #@return [Boolean] 必須入力フラグ
  attr_accessor :required

  #@return [String] 入力フィルター
  attr_accessor :filter

  #@return [String] htmlタグ生成時のtype文字列
  attr_accessor :tag_type

  #@return [Hash] htmlタグ生成時の追加アトリビュート
  attr_accessor :tag_attr

  #@return [Boolean] 値が外部で生成されて、フォーム入力ではない事を示すフラグ
  attr_accessor :foreign

  #@return [Boolean] HTMLタグ input type="hidden" として生成するかのフラグ
  attr_accessor :hidden

  #@return [String] メッセージ
  attr_reader :message


  ##
  # (AlWidget) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@option arg [String] :label          ラベル文字列
  #@option arg [Object] :value          初期値
  #@option arg [Boolean] :required      必須入力フラグ
  #@option arg [Proc] :filter           入力値フィルター
  #@option arg [String] :tag_type       htmlタグ生成時のtype文字列
  #@option arg [Hash] :tag_attr         htmlタグ要素の追加アトリビュート
  #@option arg [Boolean] :foreign       値が外部で生成されるかのフラグ
  #@option arg [Boolean] :hidden        hiddenタグとして生成するかのフラグ
  #
  def initialize( name, arg = {} )
    @name = name.to_s
    @label = arg[:label] || @name
    @value = arg[:value]     # (note) 初期値にはfilterをかける必要はないだろう
    @value_format = arg[:value_format]
    @required = arg[:required]
    @filter = arg[:filter]
    @tag_type = arg[:tag_type] if arg[:tag_type]
    @tag_attr = arg[:tag_attr] || {}
    @foreign = arg[:foreign]
    @hidden = arg[:hidden]
    @message = ""
  end


  ##
  # (AlWidget) 値のセット
  #
  #@param v    セットする値
  #
  def set_value( v )
    @value = v
  end
  alias value= set_value


  ##
  # (AlWidget) アトリビュートの設定
  #
  #@param [Hash] arg    セットする値
  #@note 名称はsetだが、実質はaddである。
  #      一貫していないようだが、テンプレートとの兼ね合いもあり、
  #      この名称の方が自然に記述できる。
  #
  def set_attr( arg )
    @tag_attr.merge!( arg )
  end


  ##
  # (AlWidget) HTMLタグの生成
  #
  #@param [Hash] appendix_tag   htmlタグへ追加するアトリビュートを指定
  #@return [String]             htmlタグ
  #
  def make_tag( appendix_tag = {} )
    if @hidden
      return %Q(<input type="hidden" name="#{@name}" id="#{@name}" value="#{Alone::escape_html( @value )}">\n)
    end

    r = %Q(<input type="#{@tag_type || "text"}" name="#{@name}" id="#{@name}" value="#{Alone::escape_html( @value )}")
    make_tag_attr(r, appendix_tag)
    r << ">"
    return r
  end


  ##
  # (AlWidget) HTML値の生成
  #
  #@param  [String] arg 表示値。指定なければ内部値を使う。
  #@return [String]     html文字列
  #
  def make_value( *arg )
    return Alone::escape_html( arg.empty? ? @value : arg[0] )
  end


  private
  ##
  # (AlWidget) HTMLタグ生成サブルーチン
  #
  def make_tag_attr(dest, appendix_tag)
    @tag_attr.each {|k,v|
      dest << (v ? %Q( #{k}="#{Alone::escape_html(v)}") : " #{k}")
    }
    appendix_tag.each {|k,v|
      dest << (v ? %Q( #{k}="#{Alone::escape_html(v)}") : " #{k}")
    }
  end

end     # /AlWidget



##
# テキストウィジェット
#
class AlText < AlWidget

  #@return [Regexp]  正規表現によるバリデータ。正常パターンを登録する。
  attr_accessor :validator

  #@return [Integer]  最大長さ
  attr_accessor :max

  #@return [Integer]  最小長さ
  attr_accessor :min


  ##
  # (AlText) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@option arg [Regexp] :validator      バリデータ正規表現
  #@option arg [Integer] :max           最大長さ
  #@option arg [Integer] :min           最小長さ
  #@see AlWidget#initialize     argは親クラスも参照
  #
  def initialize( name, arg = {} )
    super( name, arg )
    @validator = arg[:validator] || /[^\x00-\x1F\x7F]/
    @max = arg[:max]
    @min = arg[:min]
  end


  ##
  # (AlText) 値のセット
  #
  #@param [String] v    セットする値
  #
  def set_value( v )
    @value = v.to_s
  end
  alias value= set_value


  ##
  # (AlText) バリデート
  #
  #@return [Boolean]            成否
  #
  def validate()
    @message = ""

    if @value == "" || @value == nil
      if @required
        @message = "#{@label}を入力してください。"
        return false
      end
      return true
    end

    if @max && @value.length > @max
      @message = "#{@label}は、最大#{@max}文字で入力してください。"
      return false
    end
    if @min && @value.length < @min
      @message = "#{@label}は、最低#{@min}文字入力してください。"
      return false
    end

    if @validator !~ @value
      @message = "#{@label}を正しく入力してください。"
      return false
    end

    return true
  end

end     # /AlText



##
# ヒドゥンテキストウィジェット
#
class AlHidden < AlText

  ##
  # (AlHidden) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@see AlText#initialize       argは親クラスを参照
  #
  def initialize( name, arg = {} )
    super( name, arg )
    @hidden = true
  end

end



##
# パスワードウィジェット
#
class AlPassword < AlText

  ##
  # (AlPassword) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@see AlText#initialize       argは親クラスも参照
  #
  def initialize( name, arg = {} )
    @tag_type ||= "password"
    super( name, arg )
  end


  ##
  # (AlPassword) HTML値の生成
  #
  #@return [String]     html文字列
  #@note 表示しない
  #
  def make_value( *arg )
    return '********'
  end

end



##
# テキストエリアウィジェット
#
class AlTextArea < AlText

  ##
  # (AlTextArea) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@option arg [Integer] :rows  行数
  #@option arg [Integer] :cols  列数
  #@see AlText#initialize       argは親クラスも参照
  #
  def initialize( name, arg = {} )
    super( name, arg )
    @validator = arg[:validator] || /[^\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/

    # html必須属性(rows, cols)のセット
    @tag_attr[:rows] = arg[:rows] || 3
    @tag_attr[:cols] = arg[:cols] || 40
  end


  ##
  # (AlTextArea) HTMLタグの生成
  #
  #@param [Hash] appendix_tag   htmlタグへ追加するアトリビュートを指定
  #@return [String]             htmlタグ
  #
  def make_tag( appendix_tag = {} )
    return super( appendix_tag )  if @hidden

    r = %Q(<textarea name="#{@name}" id="#{@name}")
    make_tag_attr(r, appendix_tag)
    r << ">#{Alone::escape_html( @value )}</textarea>\n"
    return r
  end


  ##
  # (AlTextArea) HTML値の生成
  #
  #@param  [String] arg 表示値。指定なければ内部値を使う。
  #@return [String]     html文字列
  #@note 改行を<br>タグに変換しながら出力する。
  #
  def make_value( *arg )
    return Alone::escape_html_br( arg.empty? ? @value : arg[0] )
  end

end



##
# セレクタウィジェット スーパークラス
#
# （チェックボックス、プルダウンメニュー、ラジオボタン）
#
class AlSelector < AlWidget

  #[Hash]  選択項目のハッシュ
  attr_reader :options

  #[String]  HTMLタグを生成する場合のタグ間セパレータ
  attr_reader :separator

  ##
  # (AlSelector) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@option arg [Hash] :options  選択オプションのハッシュ
  #@option arg [String] :separator  HTMLタグを生成する場合のタグ間セパレータ
  #@see AlWidget#initialize     argは親クラスも参照
  #
  def initialize( name, arg = {} )
    super( name, arg )
    @options = arg[:options]
    @separator = arg[:separator]
    raise "Need ':options' parameter when make widget."  if ! @options
  end


  ##
  # (AlSelector) 値のセット
  #
  #@param [String,NilClass] v   セットする値
  #
  def set_value( v )
    # 選択されない場合をnilで統一するため、ヌルストリングはnilへ変換する。
    @value = (v == "") ? nil : v
  end
  alias value= set_value


  ##
  # (AlSelector) バリデート
  #
  #@return [Boolean]            成否
  #
  def validate()
    @message = ""

    if @value == "" || @value == nil
      if @required
        @message = "#{@label}を選んでください。";
        return false
      end
      return true
    end

    if ! @options[@value.to_sym] && ! @options[@value.to_s] && ! @options[@value.to_i]
      @message = "#{@label}の入力が、規定値以外です。";
      return false
    end

    return true
  end


  ##
  # (AlSelector) HTMLタグの生成
  #
  #@param [Hash] appendix_tag   htmlタグへ追加するアトリビュートを指定
  #@return [String]             htmlタグ
  #@note フラグ @hidden の時のみ対応。その他はサブクラスへ委譲。appendix_tagは使わない
  #
  def make_tag( appendix_tag = {} )
    @options.each do |k,v|
      if @value && @value.to_s == k.to_s
        return %Q(<input type="hidden" name="#{@name}" id="#{@name}" value="#{Alone::escape_html(k)}">\n)
      end
    end

    return ""
  end


  ##
  # (AlSelector) HTML値の生成
  #
  #@param  [String] arg 表示値。指定なければ内部値を使う。
  #@return [String]     html文字列
  #
  def make_value( *arg )
    v = arg.empty? ? @value : arg[0]
    if v == "" || v == nil
      return ""
    end
    return Alone::escape_html( @options[v] || @options[v.to_sym] || @options[v.to_s] || @options[v.to_i] )
  end

end     # /AlSelector



##
# チェックボックスウィジェット
#
class AlCheckboxes < AlSelector

  #@return [Integer]  最大チェック数
  attr_accessor :max

  #@return [Integer]  最小チェック数
  attr_accessor :min


  ##
  # (AlCheckboxes) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@option arg [Integer] :max   最大チェック数
  #@option arg [Integer] :min   最小チェック数
  #@see AlSelector#initialize   argは親クラスも参照
  #
  def initialize( name, arg = {} )
    super( name, arg )
    @value = set_value( @value )
    @max = arg[:max]
    @min = arg[:min]
  end


  ##
  # (AlCheckboxes) 値のセット
  #
  #@param  value        セットする値
  #
  def set_value( value )
    case value
    when Array
      @value = []
      value.flatten.each do |v|
        case v
        when String,TrueClass,FalseClass,Numeric
          @value << v.to_s
        end
      end

    when String
      @value = value.split(',')

    when TrueClass,FalseClass
      @value = [ value.to_s ]

    else
      @value = []
    end
  end
  alias value= set_value


  ##
  # (AlCheckboxes) バリデーション
  #
  #@return [Boolean]            成否
  #
  def validate()
    @message = ""

    if @max && @value.size > @max
      @message = "#{@label}は、最大#{@max}個選んでください。"
      return false
    end
    if @min && @value.size < @min
      @message = "#{@label}は、最低#{@min}個選んでください。"
      return false
    end

    if @value.empty? && @required
      @message = "#{@label}を選んでください。";
      return false
    end

    @value.each { |v|
      if ! @options[v.to_sym] && ! @options[v.to_s] && ! @options[v.to_i]
        @message = "#{@label}の入力が、規定値以外です。";
        return false
      end
    }

    return true
  end


  ##
  # (AlCheckboxes) HTMLタグの生成
  #
  #@param [Hash] appendix_tag   htmlタグへ追加するアトリビュートを指定
  #@return [String]             htmlタグ
  #
  def make_tag( appendix_tag = {} )
    r = ""
    if @hidden
      tag = %Q(<input type="hidden" name="#{@name}")
      @options.each do |k,v|
        if @value.include?(k.to_sym) || @value.include?(k.to_s)
          tagvalue = Alone::escape_html( k.to_s )
          r << %Q(#{tag} id="#{@name}_#{tagvalue}" value="#{tagvalue}">\n)
        end
      end
    else
      @options.each do |k,v|
        checked = @value.include?(k)
        if ! checked
          case k
          when Numeric
            checked = @value.include?(k.to_s)
          when String
            checked = @value.include?(k.to_sym)
          when Symbol
            checked = @value.include?(k.to_s)
          end
        end
        checked = checked ? " checked" : ""

        tagvalue = Alone::escape_html( k.to_s )
        r << %Q(<label><input type="checkbox" name="#{@name}" id="#{@name}_#{tagvalue}" value="#{tagvalue}"#{checked})
        make_tag_attr(r, appendix_tag)
        r << ">#{Alone::escape_html(v)}</label>#{@separator}\n"
      end
    end

    return r
  end


  ##
  # (AlCheckboxes) HTML値の生成
  #
  #@param  [String,Array<String>] arg 表示値。指定なければ内部値を使う。
  #@return [String]     html文字列
  #
  def make_value( *arg )
    v = arg.empty? ? @value : arg[0]
    if v.class == String
      v = v.split(',')
    end
    r = ""
    v.each do |k|
      r << Alone::escape_html( @options[k.to_sym] || @options[k.to_s] || @options[k.to_i] ) << " "
    end
    return r
  end

end     # /AlCheckboxes



##
# セレクトオプションウィジェット（プルダウンメニュー）
#
class AlOptions < AlSelector

  ##
  # (AlOptions) HTMLタグの生成
  #
  #@param [Hash] appendix_tag   htmlタグへ追加するアトリビュートを指定
  #@return [String]             htmlタグ
  #
  def make_tag( appendix_tag = {} )
    return super( appendix_tag )  if @hidden

    r = %Q(<select name="#{@name}" id="#{@name}")
    make_tag_attr(r, appendix_tag)
    r << ">\n"
    @options.each do |k,v|
      selected = (@value && @value.to_s == k.to_s) ? " selected": ""
      tagvalue = Alone::escape_html( k.to_s )
      r << %Q(<option id="#{name}_#{tagvalue}" value="#{tagvalue}"#{selected}>#{Alone::escape_html(v)}</option>\n)
    end
    return r + "</select>\n"
  end

end



##
# ラジオボタンウィジェット
#
class AlRadios < AlSelector

  ##
  # (AlRadios) htmlタグの生成
  #
  #@param [Hash] appendix_tag   htmlタグへ追加するアトリビュートを指定
  #@return [String]             htmlタグ
  #
  def make_tag( appendix_tag = {} )
    return super( appendix_tag )  if @hidden

    r = ""
    @options.each do |k,v|
      checked = (@value && @value.to_s == k.to_s) ? " checked" : ""
      tagvalue = Alone::escape_html( k.to_s )
      r << %Q(<label><input type="radio" name="#{@name}" id="#{@name}_#{tagvalue}" value="#{tagvalue}"#{checked})
      make_tag_attr(r, appendix_tag)
      r << ">#{Alone::escape_html(v)}</label>#{@separator}\n"
    end

    return r
  end

end



##
# ファイルウィジェット
#
class AlFile < AlWidget

  ##
  # (AlFile) constructor
  #
  def initialize( name, arg = {} )
    require 'al_form/input_file'

    super( name, arg )
  end

end



##
# ボタンウィジェット
#
class AlButton < AlWidget

  ##
  # (AlButton) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@see AlWidget#initialize     argは親クラスを参照
  #
  def initialize( name, arg = {} )
    @tag_type ||= "button"
    super( name, arg )
    @label = arg[:label] || ""
    @value ||= name
  end


  ##
  # (AlButton) 値のセット
  #
  #@param v        セットする値
  #@note なにもしない。
  #
  def set_value( v )
  end
  alias value= set_value


  ##
  # (AlButton) バリデート
  #
  #@return [Boolean]    always true
  #
  def validate()
    return true
  end


  ##
  # (AlButton) HTML値の生成
  #
  #@return [String]     表示しないため、ヌルストリングを返す
  #
  def make_value( *arg )
    return ""
  end

end


##
# サブミットボタンウィジェット
#
class AlSubmit < AlButton

  ##
  # (AlSubmit) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@see AlButton#initialize     argは親クラスを参照
  #
  def initialize( name, arg = {} )
    @tag_type ||= "submit"
    super( name, arg )
  end

end



##
# メールアドレス入力ウィジェット
#
#
class AlMail < AlText

  ##
  # (AlMail) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@see AlText#initialize       argは親クラスを参照
  #
  def initialize( name, arg = {} )
    part = %r([a-zA-Z0-9_\#!$%&`'*+\-{|}~^/=?\.]+)

    super( name, arg )
    @filter = arg[:filter] || AlForm::FILTER_STRIP
    @validator = %r(\A#{part}@#{part}\z)
  end

end



##
# 数値入力ウィジェット
#
class AlNumber < AlWidget

  #@return [Integer]  最大値
  attr_accessor :max

  #@return [Integer]  最小値
  attr_accessor :min

  ##
  # (AlNumber) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@option arg [Integer] :max   最大値
  #@option arg [Integer] :min   最小値
  #@see AlWidget#initialize     argは親クラスも参照
  #
  def initialize( name, arg = {} )
    super( name, arg )
    @max = arg[:max]
    @min = arg[:min]
  end


  ##
  # (AlNumber) HTML値の生成
  #
  #@param  [String] arg 表示値。指定なければ内部値を使う。
  #@return [String]     html文字列
  #
  def make_value( *arg )
    v = arg.empty? ? @value : arg[0]
    v = sprintf( @value_format, v ) if @value_format && v
    return Alone::escape_html( v )
  end

end



##
# 整数値入力ウィジェット
#
class AlInteger < AlNumber

  ##
  # (AlInteger) バリデート
  #
  #@return [Boolean]            成否
  #
  def validate()
    @message = ""

    if @value == "" || @value == nil
      if @required
        @message = "#{@label}を入力してください。"
        return false
      end
      @value = nil
      return true
    end

    if /^[\s]*[+-]?[\d]+[\s]*$/ !~ @value.to_s
      @message = "#{@label}は整数で入力してください。"
      return false
    end

    v = @value.to_i
    if @max && v > @max
      @message = "#{@label}は、#{@max}以下を入力してください。"
      return false
    end
    if @min && v < @min
      @message = "#{@label}は、#{@min}以上を入力してください。"
      return false
    end
    @value = v

    return true
  end

end



##
# 浮動小数点入力ウィジェット
#
class AlFloat < AlNumber

  ##
  # (AlFloat) バリデート
  #
  #@return [Boolean]            成否
  #
  def validate()
    @message = ""

    if @value == "" || @value == nil
      if @required
        @message = "#{@label}を入力してください。"
        return false
      end
      @value = nil
      return true
    end

    if /^[\s]*[+-]?[\d]+(\.[\d]+)?([eE][+-]?[\d]+)?$/ !~ @value.to_s
      @message = "#{@label}を正しく入力してください。"
      return false
    end

    v = @value.to_f
    if @max && v > @max
      @message = "#{@label}は、#{@max}以下を入力してください。"
      return false
    end
    if @min && v < @min
      @message = "#{@label}は、#{@min}以上を入力してください。"
      return false
    end
    @value = v

    return true
  end

end



##
# タイムスタンプウィジェット
#
#@note 年月日と時分秒を扱う
# 内部的にはTimeオブジェクトで保存する。
#
class AlTimestamp < AlWidget
  require "time"

  STRFTIME_FORMAT = "%Y-%m-%d %H:%M:%S"

  #@return [Integer]  最大値
  attr_accessor :max

  #@return [Integer]  最小値
  attr_accessor :min


  ##
  # (AlTimestamp) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@option arg [Integer] :max   最大値
  #@option arg [Integer] :min   最小値
  #@see AlWidget#initialize     argは親クラスも参照
  #
  def initialize( name, arg = {} )
    super( name, arg )

    @value_format ||= self.class::STRFTIME_FORMAT
    @filter = arg[:filter] || AlForm::FILTER_STRIP
    @max = normalize( arg[:max] )
    @min = normalize( arg[:min] )
  end


  ##
  # (AlTimestamp) バリデート
  #
  #@return [Boolean]            成否
  #
  def validate()
    @message = ""

    if @value == "" || @value == nil
      if @required
        @message = "#{@label}を入力してください。"
        return false
      end
      @value = nil
      return true
    end

    begin
      @value = normalize( @value.to_s )
    rescue
      @message = "#{@label}を正しく入力してください。"
      return false
    end

    if @max && @value > @max
#      @message = "#{@label}は、最大#{@max.strftime(self.class::STRFTIME_FORMAT)}までで入力してください。"
      @message = "#{@label}は、最大#{@max.strftime(@value_format)}までで入力してください。"
      return false
    end
    if @min && @value < @min
      @message = "#{@label}は、最小#{@min.strftime(@value_format)}までで入力してください。"
      return false
    end

    return true
  end


  ##
  # (AlTimestamp) HTMLタグの生成
  #
  #@param [Hash] appendix_tag   htmlタグへ追加するアトリビュートを指定
  #@return [String]             htmlタグ
  #
  def make_tag( appendix_tag = {} )
    if @hidden
      return %Q(<input type="hidden" name="#{@name}" id="#{@name}" value="#{make_value()}">\n)
    end

    r = %Q(<input type="#{@tag_type || "text"}" name="#{@name}" id="#{@name}" value="#{make_value()}")
    make_tag_attr(r, appendix_tag)
    r << ">"
    return r
  end


  ##
  # (AlTimestamp) HTML値の生成
  #
  #@param  [String,Time] arg 表示値。指定なければ内部値を使う。
  #@return [String]     html文字列
  #
  def make_value( *arg )
    v = arg.empty? ? @value : arg[0]
    if v.class == Time
      return v.strftime( @value_format )
    else
      return Alone::escape_html( v )
    end
  end


  private
  ##
  # (AlTimestamp) 正規化
  #
  #@param [String,Time] v
  #@return [Time]
  #
  def normalize( v )
    case v
    when Time
      return v
    when String
      return Time.parse( v )
    end
    return nil
  end

end     # /AlTimestamp



##
# 日付ウィジェット
#
#@note
# 年月日を扱う
# 内部的には時刻を0時に固定したTimeオブジェクトで保存する。
#
class AlDate < AlTimestamp

  STRFTIME_FORMAT = "%Y-%m-%d"

  ##
  # (AlDate) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@see AlTimestamp#initialize  argは親クラスも参照
  #
  def initialize( name, arg = {} )
    super( name, arg )
    @value = normalize( @value )  if @value.class == Time
  end


  private
  ##
  # (AlDate) 正規化
  #
  #@param [String,Time] v
  #@return [Time]
  #
  def normalize( v )
    if v.class == String
      v = Time.parse( v )
    end
    if v.class == Time
      return Time.new( v.year, v.month, v.day )
    end
    return nil
  end

end     # /AlDate



##
# 時刻ウィジェット
#
#@note
# 時分秒を扱う
# 内部的には日付を2000年に固定したTimeオブジェクトで保存する。
#
class AlTime < AlTimestamp

  STRFTIME_FORMAT = "%H:%M:%S"

  ##
  # (AlTime) constructor
  #
  #@param [String] name         ウィジェット識別名　英文字を推奨
  #@param [Hash] arg            引数ハッシュ
  #@see AlTimestamp#initialize  argは親クラスも参照
  #
  def initialize( name, arg = {} )
    super( name, arg )
    @value = normalize( @value )  if @value.class == Time
  end


  private
  ##
  # (AlTime) 正規化
  #
  #@param [String,Time] v
  #@return [Time]
  #
  def normalize( v )
    case v
    when String
      return Time.parse("2000-01-01 #{v}")
    when Time
      return Time.new( 2000, 1, 1, v.hour, v.min, v.sec )
    end
    return nil
  end

end     # /AlTime
