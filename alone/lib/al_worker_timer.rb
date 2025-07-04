#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# alone : application framework for embedded systems.
#          Copyright (c) 2009-2012 Inas Co Ltd. All Rights Reserved.
#          Copyright (c) 2018-2020 Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require "al_worker"

##
# タイマー
#
class AlWorker::Timer

  #@return [Boolean]  シングルショットタイマーか？
  attr_reader :is_singleshot

  #@return [Numeric,Time]  タイマー開始 (sec)
  attr_accessor :timeup

  #@return [Numeric]    タイマー間隔 (sec)
  attr_accessor :interval

  #@return [Symbol]  タイムアップ時の動作　同期(:sync)／非同期(:async)
  attr_accessor :mode_sync

  #@return [Boolean]  動作中か？
  attr_reader :is_start


  ##
  # constructor
  #@note
  # ユーザプログラムからは直接使わない。
  #
  def initialize( a1, a2, a3 )
    @timeup = a1
    @interval = a2
    @mode_sync = a3

    @is_singleshot = !@interval
    @is_start = false
  end


  ##
  # シングルショットタイマーの生成
  #
  #@overload singleshot( timeup )
  #  @param [Numeric]  timeup タイムアップ時間（秒）
  #@overload singleshot( timeup )
  #  @param [Time]  timeup タイムアップ時間（時刻）
  #@return [AlWorker::Timer]
  #
  def self.singleshot( timeup = nil )
    return self.new( timeup, nil, :sync )
  end


  ##
  # 繰り返しタイマーの生成
  #
  #@param [Numeric]       interval タイマー間隔（秒）
  #@param [Numeric,Time]  timeup   初期起動までの時間（秒）
  #@return [AlWorker::Timer]
  #
  def self.periodic( interval = nil, timeup = nil )
    return self.new( timeup, interval, :sync )
  end


  ##
  # タイマー開始
  #
  #@param [Array] arg   ブロックに渡す引数
  #@yield               タイムアップ時の動作
  #@return [Boolean]  開始できたか？
  #
  def run( *arg )
    return false  if @is_start
    @is_start = true

    @thread = Thread.start( arg ) {|arg|
      @timeup ||= @interval

      # sleep until first exec.
      case @timeup
      when Numeric
        sleep @timeup  if @timeup > 0
      when Time
        dt = @timeup.to_f - Time.now.to_f
        sleep dt  if dt > 0
      else
        raise self.to_s + ": sleep time must be Numeric or Time."
      end

      int_timeup = Time.now.to_f

      while true
        # fire!
        begin
          Thread.exit  if Thread.current[:flag_stop] || ! block_given?
          if mode_sync == :sync
            AlWorker.mutex_sync.synchronize { yield( *arg ) }
          else
            yield( *arg )
          end

        rescue Exception => ex
          raise ex  if ex.class == SystemExit
          AlWorker.log( ex )
        end

        if @is_singleshot
          @is_start = false
          break         # break a while and thread.
        end

        # sleep next interval
        int_timeup += @interval
        dt = int_timeup - Time.now.to_f
        if dt > 0
          sleep dt
        else
          # over the interval, restart now time.
          int_timeup = Time.now.to_f
          Thread.pass
        end
      end
    }

    return true
  end


  ##
  # タイマー停止
  #
  def stop()
    @thread[:flag_stop] = true  if @thread
    @is_start = false
  end

end
