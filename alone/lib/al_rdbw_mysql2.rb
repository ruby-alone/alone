#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# alone : application framework for embedded systems.
#          Copyright (c) 2019 Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# Using mysql2 (0.5.2)

require "mysql2"
require "al_rdbw"


##
# リレーショナルデータベースラッパー MySQL2版
#
class AlRdbwMysql2 < AlRdbw

  Mysql2::Client.default_query_options[:symbolize_keys] = true


  ##
  # RDBサーバとのコネクションを開始する
  #
  def open_connection()
    return false  if ! @dsn

    @handle = Mysql2::Client.new(@dsn)
    @dsn = nil
  end


  ##
  # 任意SQLの実行
  #
  #@param  [String] sql     SQL文
  #@param  [Array]  values  パラメータクエリ用変数
  #@return [Hash]           結果
  #@note
  # アクションクエリの実行用。selectは、select()メソッドを使う。
  #
  def execute( sql, values = [] )
    # MySQLでは、"lock tables" 等は、query()でしか実行できない。
    begin
      stmt = get_handle().prepare( sql )
    rescue Mysql2::Error => ex
      raise ex  if ex.errno != 1295 # ER_UNSUPPORTED_PS
      raise ex  if ! values.empty?
      get_handle().query( sql )
      return {}
    end

    stmt.execute( *values )
    ret = { :cmdtuples=>stmt.affected_rows(), :insert_id=>stmt.last_id() }
    stmt.close()
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
  #  use Array
  #   select( "select * from t1 where id=?;", [2] )
  #  use Hash
  #   select( "select * from t1 _WHERE_;",
  #     { :id=>2, :age=>nil, "name like"=>"a%" } )
  #
  def select( sql, where_cond = nil )
    case where_cond
    when NilClass
      args = []

    when Array
      args = where_cond

    when Hash
      s = sql.split("_WHERE_")
      raise "SQL error in select()"  if s.size != 2
      (where, args) = make_where_condition( where_cond )
      sql = "#{s[0]} where #{where} #{s[1]}"

    when String
      args = []
      sql = sql.sub("_WHERE_", "where #{where_cond}")

    else
      raise "where_cond error in AlRdbwMysql#select()"
    end

    @stmt = get_handle().prepare( sql )
    if @select_data_type == :ARRAY
      @exec_result = @stmt.execute( *args, :as=>:array )
    else
      @exec_result = @stmt.execute( *args )
    end

    # get field name
    @fields = @stmt.fields.map {|field| field.to_sym }

    # get data (row mode)
    if @select_fetch_mode == :ROW
      @fiber = Fiber.new {
        @exec_result.each {|row| Fiber.yield( row ) }

        @exec_result.free()
        @stmt.close()
        @exec_result = @stmt = nil
      }
      return select_next()
    end

    # get data all
    ret = @exec_result.each {}

    # return
    @exec_result.free()
    @stmt.close()
    @exec_result = @stmt = nil
    return ret
  end


  ##
  # シングル行モード(select_fetch_mode = :ROW)の場合の次行取得
  #
  #@return [Array,Hash,Nil] 結果
  #@example
  #  res = db.select( sql )
  #  p db.fields
  #  while res
  #    p res
  #    res = db.select_next()
  #  end
  #
  def select_next()
    return nil  if !@stmt

    return @fiber.resume
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
      if v.class == Array
        val << v.join(",")
      else
        val << v
      end
    end
    col.chop!
    plh.chop!

    sql = "insert into #{table} (#{col}) values (#{plh});"
    stmt = get_handle().prepare( sql )
    stmt.execute( *val )
    ret = { :cmdtuples=>stmt.affected_rows(), :insert_id=>stmt.last_id() }
    stmt.close()
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
    val = []
    values.each do |k,v|
      columns << "#{k}=?,"
      if v.class == Array
        val << v.join(",")
      else
        val << v
      end
    end
    columns.chop!

    (where, wval) = make_where_condition( where_cond )
    sql = "update #{table} set #{columns} where #{where};"
    val += wval

    stmt = get_handle().prepare( sql )
    stmt.execute( *val )
    ret = { :cmdtuples=>stmt.affected_rows() }
    stmt.close()
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

    stmt = get_handle().prepare( sql )
    stmt.execute( *wval )
    ret = { :cmdtuples=>stmt.affected_rows() }
    stmt.close()
    return ret
  end


  ##
  # トランザクション開始
  #
  #@return [Boolean]    成否
  #
  def transaction()
    return false  if @flag_transaction
    get_handle().query("begin;")
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
    get_handle().query("commit;")
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
    get_handle().query("rollback;")
    @flag_transaction = false
    return true
  end

end
