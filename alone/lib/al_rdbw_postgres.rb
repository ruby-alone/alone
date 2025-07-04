#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# alone : application framework for embedded systems.
#          Copyright (c) 2009-2012 Inas Co Ltd. All Rights Reserved.
#          Copyright (c) 2018-2019 Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# Using pg (1.1.3)

require 'pg'
require 'al_rdbw'


##
# リレーショナルデータベースラッパー PostgreSQL版
#
class AlRdbwPostgres < AlRdbw

  #@return [Object] クエリ実行結果
  attr_reader :result


  ##
  # RDBサーバとのコネクションを開始する
  #
  def open_connection()
    return false  if ! @dsn

    @handle = PG::Connection.new( @dsn )
    @handle.set_client_encoding( AL_CHARSET.to_s )
    @handle.type_map_for_results = PG::BasicTypeMapForResults.new(@handle)
    @dsn = nil
  end


  ##
  # 任意SQLの実行
  #
  #@param  [String] sql  SQL文
  #@param  [Array]  var  パラメータクエリ用変数
  #@return [Hash] 結果
  #@note
  # アクションクエリの実行用。selectは、select()メソッドを使う。
  #
  def execute( sql, var = nil )
    @result = get_handle().exec( sql, var )
    ret = { :cmdtuples=>@result.cmdtuples }
    @result.clear()
    return ret
  end
  alias exec execute


  ##
  # select文の発行ヘルパー
  #
  #@param  [String]      sql  SQL文
  #@param  [Array,Hash,String]  where_cond  where条件
  #@return [Array<Hash>] 結果の配列
  #@example
  #  where condition
  #   use Array
  #    select( "select * from t1 where id=$1;", [2] )
  #   use Hash
  #    select( "select * from t1 _WHERE_;",
  #      { :id=>2, :age=>nil, "name like"=>"a%" } )
  #
  def select( sql, where_cond = nil )
    conn = get_handle()

    case where_cond
    when NilClass
      conn.send_query( sql )

    when Array
      conn.send_query_params( sql, where_cond );

    when Hash
      s = sql.split( '_WHERE_' )
      raise "SQL error in select()"  if s.size != 2
      (where, val) = make_where_condition( where_cond )
      conn.send_query_params( "#{s[0]} where #{where} #{s[1]}", val )

    when String
      conn.send_query( sql.sub( '_WHERE_', "where #{where_cond}" ))

    else
      raise "where_cond error in AlRdbwPostgres#select()"
    end

    conn.set_single_row_mode  if @select_fetch_mode == :ROW

    # get field name
    @result = conn.get_result() or return @select_fetch_mode == :ROW ? nil : []
    @result.check_result
    @fields = @result.fields().map {|field| field.to_sym }

    # get data
    ret = []
    case @select_data_type
    when :ARRAY         # Array<Array>で返す
      @result.each_row {|row| ret << row }

    else                # Array<Hash>で返す（標準）
      @result.each_row {|row| ret << [@fields, row].transpose.to_h }
    end

    return ret[0]  if @select_fetch_mode == :ROW

    @result.clear()
    conn.get_result()   # libqp needs this operation.
    return ret
  end


  ##
  # シングル行モード(select_fetch_mode = :ROW)の場合の次行取得
  #
  #@return [Array,Hash,Nil] 結果
  #@example
  # res = @db.select( sql )
  # p @db.fields
  # while res
  #   p res
  #   res = db.select_next()
  # end
  #
  def select_next()
    @result = get_handle().get_result() or return nil
    @result.check_result

    case @select_data_type
    when :ARRAY
      @result.each_row {|row| return row }

    else
      @result.each_row {|row| return [@fields, row].transpose.to_h }
    end
  end



  ##
  # insert文の発行ヘルパー
  #
  #@param [String]  table     テーブル名
  #@param [Hash]    values    insertする値のhash
  #@return [Hash]             結果のHash
  #
  def insert( table, values )
    col = ""
    plh = ""
    val = []
    cnt = 1
    values.each do |k,v|
      col << "#{k},"
      plh << "$#{cnt},"
      cnt += 1
      if v.class == Array
        val << v.join( ',' )
      else
        val << v
      end
    end
    col.chop!
    plh.chop!

    sql = "insert into #{table} (#{col}) values (#{plh});"
    @result = get_handle().exec( sql, val )
    ret = { :cmdtuples=>@result.cmdtuples }

    @result.clear()
    return ret
  end


  ##
  # update文の発行ヘルパー
  #
  #@param [String]  table     テーブル名
  #@param [Hash]    values    updateする値のhash
  #@param [Hash]  where_cond  where条件
  #@return [Hash]             結果のHash
  #
  def update( table, values, where_cond )
    columns = ""
    cnt = 1
    val = []
    values.each do |k,v|
      columns << "#{k}=$#{cnt},"
      cnt += 1
      if v.class == Array
        val << v.join( ',' )
      else
        val << v
      end
    end
    columns.chop!

    (where, wval) = make_where_condition( where_cond, cnt )

    sql = "update #{table} set #{columns} where #{where};"
    @result = get_handle().exec( sql, val + wval )
    ret = { :cmdtuples=>@result.cmdtuples }

    @result.clear()
    return ret
  end


  ##
  # delete文の発行ヘルパー
  #
  #@param [String]  table     テーブル名
  #@param [Hash]  where_cond  where条件
  #@return [Hash]             結果のHash
  #
  def delete( table, where_cond )
    (where, wval) = make_where_condition( where_cond )
    sql = "delete from #{table} where #{where};"
    @result = get_handle().exec( sql, wval )
    ret = { :cmdtuples=>@result.cmdtuples }

    @result.clear()
    return ret
  end


  ##
  # トランザクション開始
  #
  #@return [Boolean]    成否
  #
  def transaction()
    return false  if @flag_transaction
    @result = get_handle().exec( "begin transaction;" )
    @result.clear()
    return @flag_transaction = true
  end


  ##
  # トランザクションコミット
  #
  #@return [Boolean]    成否
  #@todo
  # 実装中。トランザクションがSQLレベルで失敗する条件をテストして返り値に反映する
  #
  def commit()
    return false  if ! @flag_transaction
    @result = get_handle().exec( "commit transaction;" )
    @result.clear()
    @flag_transaction = false
    return true
  end


  ##
  # トランザクションロールバック
  #
  #@return [Boolean]    成否
  #
  def rollback()
    return false  if ! @flag_transaction
    @result = get_handle().exec( "rollback transaction;" )
    @result.clear()
    @flag_transaction = false
    return true
  end


  private
  ##
  # where 条件がHashで与えられたときの解析
  # 複合条件は、andのみ。
  #
  def make_where_condition( where_cond, cnt = 1 )
    whe = nil
    val = []

    where_cond.each do |k,v|
      if whe
        whe << " and #{k}"
      else
        whe = "#{k}"
      end

      if v == nil
        if k.class == Symbol
          whe << " is null"
        end
        next
      end

      if k.class == Symbol    # symbolの時は、=で比較するルール
        whe << "=$#{cnt}"
      else
        whe << " $#{cnt}"
      end
      val << v
      cnt += 1
    end
    whe = "1=1" if ! whe

    return whe, val
  end

end
