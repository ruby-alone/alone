#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# alone : application framework for embedded systems.
#          Copyright (c) 2009-2012 Inas Co Ltd. All Rights Reserved.
#          Copyright (c) 2018-2023 Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require "logger"
require "etc"
require "json"
require "yaml"
require "digest/sha1"


##
# ワーカースーパークラス
#
class AlWorker

  DEFAULT_WORKDIR = "/tmp"
  DEFAULT_NAME = "al_worker"
  LOG_SEVERITY = { :fatal=>Logger::FATAL, :error=>Logger::ERROR,
    :warn=>Logger::WARN, :info=>Logger::INFO, :debug=>Logger::DEBUG }

  #@return [Logger]  ロガー
  @@log = nil

  #@return [Mutex]  同期実行用mutex
  @@mutex_sync = Mutex.new


  ##
  # 同期実行用mutexのアクセッサ
  #
  def self.mutex_sync()
    return @@mutex_sync
  end



  ##
  # ログ出力
  #
  #@param [String,Object] msg   エラーメッセージ
  #@param [Symbol] severity     ログレベル :fatal, :error ...
  #@param [String] progname     プログラム名
  #@return [Logger]             Loggerオブジェクト
  #
  def self.log( *args )
    return nil  if ! @@log
    return @@log  if args.empty?

    msg,severity,progname = *args
    s = LOG_SEVERITY[ severity ]

    case msg
    when String
      @@log.add(s || Logger::INFO, msg, progname)

    when Exception
      @@log.add(s || Logger::ERROR, "#{msg.class} / #{msg.message}", progname)
      @@log.add(s || Logger::ERROR, "BACKTRACE: \n  " + msg.backtrace.join("\n  ") + "\n", progname)

    else
      @@log.add(s || Logger::INFO, msg.inspect, progname)
    end

    return @@log
  end


  ##
  # IPC定形リクエストからコマンドとパラメータを解析・取り出し
  #
  #@param [String] req  リクエスト
  #@return [String] コマンド
  #@return [Hash] パラメータ
  #
  def self.parse_request( req )
    (cmd,param) = req.split( " ", 2 )
    return cmd,{}  if param == nil
    param.strip!
    return cmd,{}  if param.empty?
    return cmd,( JSON.parse( param ) rescue { ""=>param } )
  end


  ##
  # IPC定形リプライ
  #
  #@param [Socket]  sock    返信先ソケット
  #@param [Integer] st_code ステータスコード
  #@param [String]  st_msg  ステータスメッセージ
  #@param [Hash]    val     リプライデータ
  #@return [True]
  #@note
  # 定形リプライフォーマット
  #   (ステータスコード) "200. Message"
  #   (JSONデータ)       { .... }
  #  JSONデータは付与されない場合がある。
  #  その判断は、ステータスコードの数字直後のピリオドの有無で行う。
  #
  def self.reply( sock, st_code, st_msg, val = nil )
    sock.puts ("%03d" % st_code) + (val ? ". " : " ") + st_msg
    if val
      sock.puts val.to_json, ""
    end
    return true

  rescue Errno::EPIPE
    Thread.exit
  end


  ##
  # ステートマシンで無視するイベントの記述
  #
  #@note
  # クラス定義中に、na :state_XXX_event_YYY の様に記述する。
  #
  def self.na( method_name )
    define_method( method_name ) { |*args| }
  end


  ##
  # 文字列のコメントを取り必要に応じて変換する
  #
  #@param [String] src  source string
  #@param [Regexp] comment_pattern  comment pattern
  #@return [String,NIl] result
  #
  def self.realize_string( src, comment_pattern = /\s[;#]/ )
    # ダブルクォートで括られている場合は文字列として取り出す
    if /^\s*"/ =~ src
      if /^\s*"(([^\\"]+|\\.)*)"/ =~ src
        s = $1
      else
        return nil
      end

    else
      # コメントの削除
      if comment_pattern && (len = comment_pattern =~ src)
        s = src[0, len].strip
      else
        s = src.strip
      end

      # 数値に変換するか？
      case s
      when /^[+-]?[\d]+$/
        return s.to_i
      when /^[+-]?([\d]+(\.[\d]*)?|\.[\d]+)([eE][+-]?[\d]+)?$/
        return s.to_f
      when /^0[xX][\h_]+$/
        return s.hex
      end
    end

    # エスケープされた文字があれば展開して返す
    return s.gsub(/\\(.)/) {
      ({"0"=>"\x00", "a"=>"\x07", "b"=>"\x08",
        "t"=>"\x09", "r"=>"\x0d", "n"=>"\x0a"}[$1]) || $1
    }
  end



  #@return [Hash,Nil]  動作設定（コンフィグファイル読込結果）
  attr_accessor :config

  #@return [Hash] 外部提供を目的とする値のHash　IPCの関係でキーは文字列のみとする。
  attr_accessor :values

  #@return [Sync] @values の reader writer lock (require 'sync')
  attr_reader :values_rwlock

  #@return [String]  ワークファイルの作成場所
  attr_accessor :workdir

  #@return [String]  pidファイル名（フルパス）
  attr_accessor :pid_filename

  #@return [String]  ログファイル名（フルパス）
  attr_accessor :log_filename

  #@return [String] ユニークネーム
  attr_reader :name

  #@return [String] 現在実行中のRubyスクリプトの名前を表す文字列 $PROGRAM_NAME
  attr_accessor :program_name

  #@return [String] 実行権限ユーザ名
  attr_accessor :privilege

  #@return [String]  ステート（ステートマシン用）
  attr_reader :state

  #@return [Queue]  メインスレッド動作依頼キュー
  attr_accessor :main_queue



  ##
  # constructor
  #
  #@param [String] name  識別名
  #
  def initialize( name = nil, workdir = nil )
    @values = {}
    @values_rwlock = defined?(Sync) ? Sync.new : nil
    @name = name || DEFAULT_NAME
    @workdir = workdir || DEFAULT_WORKDIR
    @state = ""
    @pid_filename = File.join( @workdir, @name ) + ".pid"
    @main_queue = Queue.new

    Signal::trap( :HUP ) { signal_hup() }
    Signal::trap( :QUIT ) { signal_quit() }
  end


  ##
  # 基本的なオプションの解析
  #  （OptionParseクラスを使わない場合に使用）
  #
  #@param [Array<String>] argv  引数配列
  #
  def parse_option( argv = ARGV )
    i = 0
    while i < argv.size
      case argv[i]
      when "-d"                 # debug mode
        @flag_debug = true
      when "-k"                 # kill stay process.
        @flag_kill = true
      when "-r"                 # restart process.
        @flag_restart = true
      when "-p"                 # specify pid filename
        @pid_filename = argv[i += 1]
      when "-l"                 # specify log filename
        @log_filename = argv[i += 1]
      when "-c"                 # specify configfilename
        @config_filename = argv[i += 1]
      end
      i += 1
    end
  end


  ##
  # 基本的なオプションの解析を、OptionParseオブジェクトへ追加
  #
  #@param [OptionParse] opt     OptionParseオブジェクト
  #
  def append_default_option_to( opt )
    opt.on("-d", "--debug", "set debug mode.") { @flag_debug = true }
    opt.on("-k", "--kill", "kill stay process.") { @flag_kill = true }
    opt.on("-r", "--restart", "restart process.") { @flag_restart = true }
    opt.on("-p filename", "--pid=filename", "specify pid filename.") {|v|
      @pid_filename = v
    }
    opt.on("-l filename", "--log=filename", "specify log filename.") {|v|
      @log_filename = v
    }
    opt.on("-c filename", "--config=filename", "specify configfilename") {|v|
      @config_filename = v
    }
  end


  ##
  # 設定ファイルの読み込み
  #
  #@param [String] filename     設定ファイル名
  #@return [Boolean,Nil]        エラー有無, 処理なしならnil
  #
  def read_config( filename = nil )
    # ファイル名の確定
    if filename
      @config_filename = File.expand_path( filename )
    elsif @config_filename
      @config_filename = File.expand_path( @config_filename )
    else
      fn = File.join( File.dirname( File.expand_path($0) ), @name )
      begin
        @config_filename = fn + ".ini"
        break  if File.exist?( @config_filename )

        @config_filename = fn + ".yaml"
        break  if File.exist?( @config_filename )

        @config_filename = nil
      end while false
    end

    case @config_filename
    when nil
      return nil

    when /\.ini$/
      # break case. to below.

    when /\.yaml$/
      @config = YAML.load_file( @config_filename )
      return true

    else
      warn "ERROR: Config file must be .ini or .yaml"
      return false
    end

    # iniファイルの読み込み
    config = {}
    section = nil
    flag_error = false
    file = File.open( @config_filename )
    while txt = file.gets
      case txt
      # key=value
      when /^\s*(\w+)\s*=(.*)$/
        s = AlWorker.realize_string($2)
        if !s
          warn "ERROR: #{@config_filename}:#{file.lineno}: Syntax error in value"
          flag_error = true
          next
        end
        if section
          config[section][$1.to_sym] = s
        else
          config[$1.to_sym] = s
        end

      # section
      when /^\s*\[(\w+)\]/
        config = {""=>config}  if !config.empty? && !section
        section = $1.to_sym
        config[section] ||= {}

      # comment or empty line.
      when /^\s*[;#]/, /^\s*$/
        # nothing to do.

      else
        warn "ERROR: #{@config_filename}:#{file.lineno}: Syntax error"
        flag_error = true
      end
    end
    file.close
    @config = config

    return !flag_error

  rescue Psych::SyntaxError=>ex
    warn "ERROR: #{ex.message}"
    return false
  end


  ##
  # シグナルハンドラ　HUP
  #
  #@note
  # この実装はコンフィグファイルを読むだけだが、必要に応じてオーバライドして、
  # 処理変更のための仕組みを追加する。
  #
  def signal_hup()
    @main_queue << Proc.new {
      log("Reload config file.")
      read_config()
    }
  end


  ##
  # シグナルハンドラ　SIGQUIT
  #
  #@note
  # デバグ用
  #  状態をファイルに書き出す。
  #  画面があれば、表示する。
  #
  def signal_quit()
    save_values()

    if STDOUT.isatty
      puts "\n===== @values ====="
      @values.keys.sort.each do |k|
        puts "#{k}=> #{@values[k]}"
      end
    end
  end


  ##
  # valueのセッター（単一値）
  #
  #@param [String]  key  キー
  #@param [Object]  val  値
  #
  def set_value( key, val )
    @values_rwlock.synchronize( Sync::EX ) { @values[ key.to_s ] = val }

  rescue NameError =>ex
    raise "Need gem 'sync' and require 'sync' in your program."
  end


  ##
  # valueのセッター（複数値）
  #
  #@param [Hash] values  セットする値
  #
  def set_values( values )
    @values_rwlock.synchronize( Sync::EX ) { @values.merge!( values ) }

  rescue NameError =>ex
    raise "Need gem 'sync' and require 'sync' in your program."
  end


  ##
  # valueのゲッター タイムアウトなし（単一値）
  #
  #@param [String] key  キー
  #@return [Object]     値
  #@note
  # 値はdupして返す。
  #
  def get_value( key )
    @values_rwlock.synchronize( Sync::SH ) {
      return @values[ key.to_s ].dup rescue @values[ key.to_s ]
    }

  rescue NameError =>ex
    raise "Need gem 'sync' and require 'sync' in your program."
  end


  ##
  # valueのゲッター タイムアウトなし（複数値）
  #
  #@param [Array]  keys  キーの配列
  #@return [Hash]        値
  #@note
  # 値はdupするが、簡素化のためにディープコピーは行っていない。
  # 文字列では問題ないが、配列などが格納されている場合は注意が必要。
  #
  def get_values( keys )
    ret = {}
    @values_rwlock.synchronize( Sync::SH ) {
      keys.each do |k|
        ret[ k.to_s ] = @values[ k.to_s ].dup rescue @values[ k.to_s ]
      end
    }
    return ret

  rescue NameError =>ex
    raise "Need gem 'sync' and require 'sync' in your program."
  end


  ##
  # valueのゲッター  タイムアウト付き（単一値）
  #
  #@param [String]  key     キー
  #@param [Numeric] timeout タイムアウト時間
  #@return [Object]         値
  #@return [Boolean]        ロック状態
  #@note
  # 値はdupして返す。
  #
  def get_value_wt( key, timeout = 1 )
    locked = false
    (timeout * 10).times {
      locked = @values_rwlock.try_lock( Sync::SH )
      break if locked
      sleep 0.1
    }

    return (@values[ key.to_s ].dup rescue @values[ key.to_s ]), locked


  rescue NameError =>ex
    raise "Need gem 'sync' and require 'sync' in your program."

  ensure
    @values_rwlock.unlock( Sync::SH ) if locked
  end


  ##
  # valueのゲッター  タイムアウト付き（複数値）
  #
  #@param [Array]   keys    キーの配列
  #@param [Numeric] timeout タイムアウト時間
  #@return [Object]         値
  #@return [Boolean]        ロック状態
  #@note
  # 値はdupするが、簡素化のためにディープコピーは行っていない。
  # 文字列では問題ないが、配列などが格納されている場合は注意が必要。
  #
  def get_values_wt( keys, timeout = 1 )
    locked = false
    (timeout * 10).times {
      locked = @values_rwlock.try_lock( Sync::SH )
      break if locked
      sleep 0.1
    }

    ret = {}
    keys.each do |k|
      ret[ k.to_s ] = @values[ k.to_s ].dup rescue @values[ k.to_s ]
    end
    return ret, locked

  rescue NameError =>ex
    raise "Need gem 'sync' and require 'sync' in your program."

  ensure
    @values_rwlock.unlock( Sync::SH ) if locked
  end


  ##
  # valueのゲッター  JSON版　タイムアウトなし
  #
  #@param [String,Array] key  取得する値のキー文字列
  #@return [String]  保存されている値のJSON文字列
  #
  def get_values_json( key = nil )
    @values_rwlock.synchronize( Sync::SH ) {
      if key.class == Array
        ret = {}
        key.each { |k| ret[ k ] = @values[ k ] }
        return ret.to_json
      end
      return ( key ? { key => @values[key] } : @values ).to_json
    }

  rescue NameError =>ex
    raise "Need gem 'sync' and require 'sync' in your program."
  end


  ##
  # valuesのゲッター  JSON版 タイムアウト付き
  #
  #@param [String,Array] key  取得する値のキー文字列
  #@param [Numeric] timeout タイムアウト時間
  #@return [String]  保存されている値のJSON文字列
  #@return [Boolean] ロック状態
  #
  def get_values_json_wt( key = nil, timeout = nil )
    locked = false
    timeout ||= 1       # can't change. see AlWorker::Ipc#ipc_a_get_values_wt()
    (timeout * 10).times {
      locked = @values_rwlock.try_lock( Sync::SH )
      break if locked
      sleep 0.1
    }
    if key.class == Array
      ret = {}
      key.each { |k| ret[ k ] = @values[ k ] }
      return ret.to_json, locked
    end
    return ( key ? { key => @values[key] } : @values ).to_json, locked

  rescue NameError =>ex
    raise "Need gem 'sync' and require 'sync' in your program."

  ensure
    @values_rwlock.unlock( Sync::SH ) if locked
  end


  ##
  # 値(@values)保存
  #
  #@note
  # 排他処理なし。
  # バックアップファイルを３つまで作成する。
  #
  def save_values()
    filename = File.join( @workdir, @name ) + ".values"
    File.rename( filename + ".bak2", filename + ".bak3" ) rescue 0
    File.rename( filename + ".bak1", filename + ".bak2" ) rescue 0
    File.rename( filename,           filename + ".bak1" ) rescue 0

    File.open( filename, "w" ) { |f|
      f.puts "DATE: #{Time.now}"
      f.puts "NAME: #{@name}"
      f.puts "SELF: #{self.inspect}"
      f.puts "VALUES: \n#{@values.to_json}"
    }
    File.open( File.join( @workdir, @name ) + ".sha1", "w" ) { |file|
      file.write( Digest::SHA1.file( filename ) )
    }
  end


  ##
  # 値(@values)読み込み
  #
  def load_values( filename = nil )
    filename ||= File.join( @workdir, @name ) + ".values"
    digest = Digest::SHA1.file( filename ) rescue nil
    return nil if ! digest      # same as file not found.

    digestfile = File.join( File.dirname(filename), File.basename(filename,".*") ) + ".sha1"
    digestfile_value = File.read( digestfile ) rescue nil
    if digestfile_value
      return nil  if digest != digestfile_value
    end

    json = ""
    File.open( filename, "r" ) { |f|
      while txt = f.gets
        break if txt == "VALUES: \n"
      end
      if txt == "VALUES: \n"
        while txt = f.gets
          json << txt
        end
      end
    }
    return nil  if json == ""
    begin
      @values = JSON.parse( json )
      return true
    rescue
      return false
    end
  end


  ##
  # デーモンになって実行
  #
  def daemon()
    if @flag_debug
      run()
    else
      run( :daemon )
    end
  end


  ##
  # 実行開始
  #
  #@param [Symbol] modes 動作モード　nul デーモンにならずに実行
  #                                  :daemon デーモンで実行
  #                                  :nostop デーモンにならずスリープもしない
  #                                  :nopid プロセスIDファイルを作らない
  #                                  :nolog ログファイルを作らない
  #                                  :exit_idle_task アイドルタスクが終了したら
  #                                                  プロセスも終了する
  #
  def run( *modes )
    # 実効権限変更（放棄）
    if @privilege
      uid = Etc.getpwnam( @privilege ).uid
      Process.uid = uid
      Process.euid = uid
    end

    # 停止 or 再実行？
    if @flag_kill || @flag_restart
      begin
        pid = File.read( @pid_filename ).to_i
        Process.kill( "TERM", pid )
      rescue Errno::ENOENT
        puts "Error: No pid file. '#{@pid_filename}'"
      rescue Errno::ESRCH
        puts "Error: No such pid=#{pid} process."
      rescue Errno::EPERM
        puts "Error: Operation not permitted for pid=#{pid} process."
      end

      exit(0)  if @flag_kill
      sleep 1
    end

    # 設定ファイル読み込み
    exit(1) if read_config() == false

    # ログ準備
    if !modes.include?(:nolog) && @@log == nil
      @log_filename ||= File.join( @workdir, @name ) + ".log"
      @@log = Logger.new( @log_filename, 3 )
      @@log.level = @flag_debug ? Logger::DEBUG : Logger::INFO
    end

    if ! modes.include?( :nopid )
      # 実行可／不可確認
      if File.directory?( @pid_filename )
        puts "ERROR: @pid_filename is directory."
        exit( 64 )
      end
      if File.exist?( @pid_filename )
        puts "ERROR: Still work."
        exit( 64 )
      end

      # プロセスIDファイル作成
      # (note) pid作成エラーの場合は、daemonになる前にここで検出される。
      File.open( @pid_filename, "w" ) { |file| file.write( Process.pid ) }
    end

    # 常駐処理
    if modes.include?( :daemon )
      Process.daemon()
      # プロセスIDファイル再作成
      if ! modes.include?( :nopid )
        File.open( @pid_filename, "w" ) { |file| file.write( Process.pid ) }
      end

      # stdout, stderrの差し替え
      if !modes.include?(:nolog)
        $stdout = StdoutTrap.new(:info)
        $stderr = StdoutTrap.new(:error)
      end
    end
    $PROGRAM_NAME = @program_name  if @program_name

    # 終了時処理
    at_exit {
      if ! modes.include?( :nopid )
        File.unlink( @pid_filename ) rescue 0
      end
      AlWorker.log( "finish", :info, @name )
    }

    # 初期化２
    AlWorker.log( "start", :info, @name )
    begin
      initialize2()
    rescue Exception => ex
      raise ex  if ex.class == SystemExit
      AlWorker.log( ex )
      raise ex  if STDERR.isatty
      exit( 64 )
    end

    # アイドルタスク
    if respond_to?( :idle_task, true )
      Thread.start {
        Thread.current.priority -= 1
        begin
          idle_task()
        rescue Exception => ex
          raise ex  if ex.class == SystemExit
          AlWorker.log( ex )
          if STDERR.isatty
            STDERR.puts ex.to_s
            STDERR.puts ex.backtrace.join("\n") + "\n"
          end
        end
        exit  if modes.include?( :exit_idle_task )
      }
    end

    # メインスレッド
    if modes.include?( :nostop )
      return
    else
      run_main_queue()
    end
  end


  ##
  # メインスレッドでの実行依頼をキューで受けて実行する
  #
  def run_main_queue()
    while true
      # Rubyのデッドロック検出を避けつつ、
      # シグナルによる依頼に備えるためループを抜けないようにする。
      if Thread.list.size == 1 && @main_queue.empty?
        sleep 1
        next
      end

      req = @main_queue.pop
      case req
      when String
        log( req )
      when Proc
        req.call()
      else
        log("main_queue_process: #{req.inspect} is not a valid request.", :error)
      end
    end
  end


  ##
  # 初期化２
  #
  #@note
  # 常駐後に処理をさせるには、これをオーバライドする。
  #
  def initialize2()
  end


  ##
  # ログ出力
  #
  #@see AlWorker.log()
  #
  def log( *args )
    AlWorker.log( *args )
  end


  ##
  # IPC定形リプライ
  #
  #@see AlWorker.reply()
  #
  def reply( sock, st_code, st_msg, val = nil )
    AlWorker.reply( sock, st_code, st_msg, val )
  end


  ##
  # ステートマシン　実行メソッド割り当て
  #
  #@param [String]  event  イベント名
  #@param [Array]   args   引数
  #
  def trigger_event( event, *args )
    @respond_to = "from_#{@state}_event_#{event}"
    if respond_to?( @respond_to )
      AlWorker.log( "st:#{@state} ev:#{event} call:#{@respond_to}", :debug, @name )
      return __send__( @respond_to, *args )
    end

    @respond_to = "state_#{@state}_event_#{event}"
    if respond_to?( @respond_to )
      AlWorker.log( "st:#{@state} ev:#{event} call:#{@respond_to}", :debug, @name )
      return __send__( @respond_to, *args )
    end

    @respond_to = "event_#{event}"
    if respond_to?( @respond_to )
      AlWorker.log( "st:#{@state} ev:#{event} call:#{@respond_to}", :debug, @name )
      return __send__( @respond_to, *args )
    end

    @respond_to = "state_#{@state}"
    if respond_to?( @respond_to )
      AlWorker.log( "st:#{@state} ev:#{event} call:#{@respond_to}", :debug, @name )
      return __send__( @respond_to, *args )
    end

    # 実行すべきメソッドが見つからない場合
    @respond_to = ""
    no_method_error( event )
  end


  ##
  # メソッドエラーの場合のエラーハンドラ
  #
  def no_method_error( event )
    raise "No action defined. state: #{@state}, event: #{event}"
  end


  ##
  # 現在のステートを宣言する
  #
  #@param [String]  state ステート文字列
  #
  def set_state( state )
    @state = state.to_s
    AlWorker.log( "change state to #{@state}", :debug, @name )
  end
  alias state= set_state
  alias next_state set_state


  ##
  # 標準出力、標準エラー出力のトラップ
  #
  #@note
  # stdout, stderrをログに記録するための機能を実装する。
  #
  class StdoutTrap
    def initialize( severity )
      @severity = severity
      @buffer = ""
    end

    def write( s )
      idx_cr = s.rindex("\n")
      if !idx_cr
        @buffer << s
        return
      end

      @buffer << s[0, idx_cr]
      AlWorker.log( @buffer, @severity )
      @buffer.clear

      if s.length != idx_cr + 1
        @buffer << s[idx_cr + 1, s.length - idx_cr - 1]
      end
    end

    def <<( arg )
      write( arg )
      return self
    end

    def flush()
      return  if @buffer.empty?
      AlWorker.log( @buffer, @severity )
      @buffer.clear
    end
  end

end
