#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# alone : application framework for embedded systems.
#               Copyright (c) 2009-2012 Inas Co Ltd. All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require "al_worker"
require "socket"

##
# TCPサーバ
#
class AlWorker::Tcp

  #@return [Array<TCPServer>]  リスンサーバ
  @@servers = []

  #@return [String] リスンアドレス
  attr_accessor :address

  #@return [Integer] リスンポート
  attr_accessor :port

  #@return [TCPServer] リスンサーバ
  attr_reader :server

  #@return [Symbol]  動作モード :thread :process
  attr_accessor :mode_service

  #@return [Symbol]  パラメータのデータ形式 :json :text
  attr_accessor :mode_param

  #@return [String]  コールバックメソッドのプレフィックス
  attr_accessor :cb_prefix

  #@return [String]  接続後のバナー表示
  attr_accessor :banner

  #@return [Encoding]  受信データのエンコーディング
  attr_reader :external_encoding


  ##
  # constructor
  #
  #@param [String] address リスンアドレス
  #@param [Integer] port   リスンポート
  #
  def initialize( address = "", port = 1944 )
    @address = address
    @port = port
    @mode_service = :thread
    @mode_param = :json
    @cb_prefix = "tcp"
    @external_encoding = Encoding::UTF_8
  end


  ##
  # 受信データのエンコーディングを指定
  #
  #@param [Encoding] encoding   エンコーディング
  #
  def set_encoding( encoding )
    @external_encoding = encoding
  end


  ##
  # 実行開始
  #
  #@param [AlWorker] obj  ワーカオブジェクト
  #@note
  # プロセスモードで動作時は、syncモードと同等の動作になる。
  #
  def run( obj )
    @me = obj
    @server = TCPServer.new( @address, @port )
    @@servers << @server

    case @mode_service
    when :process
      Thread.start {
        while true
          sock = @server.accept
          pid = AlWorker.mutex_sync.synchronize { Process.fork() }

          # child
          if !pid
            @@servers.each {|server| server.close }
            _start_service( sock )
            exit!
          end

          # parent
          sock.close
          Process.detach( pid )
        end
      }

    when :thread
      Thread.start {
        while true
          Thread.start( @server.accept ) { |sock|
            _start_service( sock )
          }
        end
      }

    else
      raise "Illegal mode_service"
    end
  end


  ##
  # TCPサービス終了
  #
  def close()
    @server.close()  if !@server.closed?()
  end



  private
  ##
  # TCPサービス開始 wrapper
  #
  def _start_service( sock )
    AlWorker.log("START CONNECTION from #{sock.peeraddr[3]}.", :debug, "TCP(#{sock.object_id})" )
    sock.set_encoding( @external_encoding )  if @external_encoding
    sock.puts @banner  if @banner
    start_service( sock )

  rescue Exception => ex
    raise ex  if ex.class == SystemExit
    AlWorker.log( ex )

  ensure
    sock.close if ! sock.closed?
    AlWorker.log("END CONNECTION.", :debug, "TCP(#{sock.object_id})" )
  end


  ##
  # TCPサービス開始
  #
  #@note
  # 一つのTCP接続は、このメソッド内のloopで連続処理する。
  #
  def start_service( sock )
    while true
      # リクエスト行取得
      req = sock.gets
      break if !req
      req.chomp!
      next if req.empty?
      AlWorker.log("receive '#{req}'", :debug, "TCP(#{sock.object_id})" )

      # リクエスト実行
      ret = _assign_method( sock, req )
      break if !ret
    end
  end


  ##
  # 実行メソッド割り当て
  #
  #@param [Socket] sock TCPソケット
  #@param [String] req リクエスト行
  #@return [Boolean]  続けてリクエストを受け付けるか、接続を切るかのフラグ
  #
  def _assign_method( sock, req )
    begin
      case @mode_param
      when :json
        (cmd,param) = AlWorker.parse_request( req )
      when :text
        (cmd,param) = req.split( " ", 2 )
        param&.strip!
      else
        raise "Illegal parameter '#{@mode_param.inspect}' in @mode_param."
      end

    rescue ArgumentError=>ex
      sock.puts "400 Bad Request, #{ex.message}"
      return true
    end

    method_name_sync = "#{@cb_prefix}_#{cmd}"
    method_name_async = "#{@cb_prefix}_a_#{cmd}"

    [@me,self].each {|obj|
      if obj.respond_to?( method_name_sync, true )
        AlWorker.log( "assign method '#{method_name_sync}'", :debug, "TCP" )
        AlWorker.mutex_sync.synchronize {
          return obj.__send__( method_name_sync, sock, param )
        }
      end
      if obj.respond_to?( method_name_async, true )
        AlWorker.log( "assign method '#{method_name_async}'", :debug, "TCP" )
        return obj.__send__( method_name_async, sock, param )
      end
    }

    _command_not_implemented( sock, req )
  end


  ##
  # 実装されていないコマンドを受信した場合の挙動
  #
  def _command_not_implemented( sock, req )
    AlWorker.log( "Command not implemented.", :debug, "TCP" )
    sock.puts "400 Error Command not implemented."
    return true
  end


  ##
  # quitコマンドの処理
  #
  def tcp_a_quit( sock, param )
    sock.puts "200 OK quit."
    return false
  end

end
