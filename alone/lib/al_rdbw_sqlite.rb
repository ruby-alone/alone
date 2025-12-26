#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# alone : application framework for embedded systems.
#          Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#          Copyright (c) 2018-2019 Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# tested with sqlite3 gem 2.7.3

require 'sqlite3'
require 'al_rdbw'


##
# リレーショナルデータベースラッパー SQLite版
#
class AlRdbwSqlite < AlRdbw

  ##
  # RDBとのコネクションを開始する
  #
  def open_connection()
    return false  if ! @dsn

    @handle = SQLite3::Database.new( @dsn )
    @handle.busy_timeout( 30000 )
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
  def execute( sql, var = [] )
    get_handle().execute( sql, var )
    ret = { :cmdtuples=>handle.changes(),
            :insert_id=>handle.last_insert_row_id() }
    return ret
  end
  alias exec execute


  ##
  # select文の発行ヘルパー
  #
  #@param  [String]      sql  SQL文
  #@param  [Array,Hash]  where_cond  where条件
  #@return [Array<Hash>] 結果の配列
  #@example
  #  where condition
  #   use Array
  #    select( "select * from t1 where id=?;", [2] )
  #   use Hash
  #    select( "select * from t1 _WHERE_;",
  #      { :id=>2, :age=>nil, "name like"=>"a%" } )
  #
  def select( sql, where_cond = nil )
    case where_cond
    when NilClass
      @result = get_handle().prepare( sql ).execute()

    when Array
      @result = get_handle().prepare( sql ).execute( where_cond )

    when Hash
      s = sql.split( '_WHERE_' )
      raise "SQL error in select()"  if s.size != 2
      (where, val) = make_where_condition( where_cond )
      @result = get_handle().prepare( "#{s[0]} where #{where} #{s[1]}" ).execute( val )

    when String
      sql.sub!( '_WHERE_', "where #{where_cond}" )
      @result = get_handle().prepare( sql ).execute()

    else
      raise "where_cond error in AlRdbwSqlite#select()"
    end

    # get field name
    @fields = @result.columns.map {|field| field.to_sym }

    return select_next()  if @select_fetch_mode == :ROW

    # get data all
    ret = []
    case @select_data_type
    when :ARRAY         # Array<Array>で返す
      @result.each {|row| ret << row }

    else                # Array<Hash>で返す（標準）
      @result.each {|row| ret << [@fields, row].transpose.to_h }
    end
    @result.close()

    return ret
  end


  ##
  # シングル行モード(select_fetch_mode = :ROW)の場合の次行取得
  #
  #@return [Array,Hash,Nil] 結果
  #@example
  #  res = db.select( sql )
  #  p @db.fields
  #  while res
  #    p res
  #    res = db.select_next()
  #  end
  #
  def select_next()
    return nil  if @result.closed?
    row = @result.next()
    if !row
      @result.close()
      return nil
    end

    case @select_data_type
    when :ARRAY
      return row

    else
      return [@fields, row].transpose.to_h
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
    values.each do |k,v|
      col << "#{k},"
      plh << "?,"
      case v
      when Array
        val << v.join( ',' )
      when String, Integer, NilClass
        val << v
      when Time
        val << v.strftime("%Y-%m-%d %H:%M:%S")
      else
        val << v.to_s
      end
    end
    col.chop!
    plh.chop!

    sql = "insert into #{table} (#{col}) values (#{plh});"
    handle = get_handle()
    handle.execute( sql, val )

    return { :cmdtuples=>handle.changes(), :insert_id=>handle.last_insert_row_id() }
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
    val = []
    values.each do |k,v|
      columns << "#{k}=?,"
      case v
      when Array
        val << v.join( ',' )
      when String, Integer, NilClass
        val << v
      else
        val << v.to_s
      end
    end
    columns.chop!

    (where, wval) = make_where_condition( where_cond )

    sql = "update #{table} set #{columns} where #{where};"
    get_handle().execute( sql, val + wval )

    return { :cmdtuples=>handle.changes() }
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
    get_handle().execute( sql, wval )

    return { :cmdtuples=>handle.changes() }
  end


  ##
  # トランザクション開始
  #
  #@return [Boolean]    成否
  #
  def transaction()
    return false  if @flag_transaction
    get_handle().execute( "begin transaction;" )
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
    get_handle().execute( "commit transaction;" )
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
    get_handle().execute( "rollback transaction;" )
    @flag_transaction = false
    return true
  end

end
