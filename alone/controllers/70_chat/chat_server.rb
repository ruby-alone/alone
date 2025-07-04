#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# alone : application framework for embedded systems.
#               Copyright (c) 2009-2013 Inas Co Ltd. All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# chat server


require "al_worker_ipc"
require "al_worker_message"
require "al_worker_debug"


class ChatServer < AlWorker

  def initialize2()
    AlWorker.log.level = Logger::DEBUG
    @ipc = Ipc.new()
    @ipc.chmod = 0666
    @ipc.run( self )
    @msg = NumberedMessage.new()
    Debug.run( self )
  end


  ##
  # 発言
  # say {"myname":"...", "message":"..."}
  #
  def ipc_say( sock, param )
    param["timestamp"] = Time.now.strftime( "%Y/%m/%d %H:%M:%S" )

    # msgキューに入れる。
    # 自動的にreceive()で待ち状態のリスナーが起こされる。
    @msg.send( param )

    reply( sock, 200, "OK" )
  end


  ##
  # メッセージ取得
  # listen {"TID":n}
  #
  def ipc_a_listen( sock, param )
    tid = param["TID"].to_i
    if tid > 0
      # TIDが有効なら、キュー内TID以降のメッセージを返す。
      # もしまだTID番が発生していなければ、ここでウェイトする。
      ret = @msg.receive( tid )
    else
      # TIDが無効なら、初期アクセスとみなして全メッセージを返す。
      ret = @msg.queue.dup()
    end

    reply( sock, 200, "OK", ret )
  end


  ##
  # メッセージ取得 by ServerSentEvent
  #
  def ipc_a_listen_ssev( sock, param )
    tid = param["LAST_EVENT_ID"]
    # 初期状態で過去メッセージを表示したくなければ、この行を有効にする。
    # if tid == 0
    #   tid = @msg.tid
    # end

    while true
      @msg.cycle( tid+1, 240 ) {|m|
        tid = m[:TID].to_i
        sock.puts "id: #{tid}"
        sock.puts "data: #{m['myname']}"
        sock.puts "data: #{m['timestamp']}"
        m["message"].each_line do |txt|
          sock.puts "data: #{txt}"
        end
        sock.puts ""
      }
      sock.puts ": ssev keepalive.\n\n"
    end

  rescue Errno::EPIPE
    AlWorker.log( "Pipe closed. (#{sock.object_id})", :debug )
    return false    # done.
  end


  ##
  # サーバ終了
  #
  def ipc_terminate( sock, param )
    reply( sock, 200, "OK program terminate." )
    exit( 0 )
  end

end


server = ChatServer.new( "chat_server" )
server.parse_option()
server.daemon()
