#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# alone : application framework for embedded systems.
#          Copyright (c) 2019 Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require 'al_persist_rdb'
require 'al_rdbw_mysql2'


##
# データ永続化 Mysql2版
#
class AlPersistMysql2 < AlPersistRDB

  ##
  # RDBサーバとのコネクションをオープンする
  #
  #@param [Hash] dsn    接続情報
  #@return [AlRdbw]     RDB wrapper オブジェクト
  #
  def self.connect( dsn = nil )
    return AlRdbwMysql2.connect( dsn )
  end

end



class AlRdbwMysql2
  # DB wrapperクラスへメソッド追加する

  ##
  # tableを指定して、Persistオブジェクトを生成
  #
  #@param  [String]  tname            テーブル名
  #@param  [Array<String,Symbol>,String,Symbol]  pkey   プライマリキー
  #@return [AlPersistMysql2]          データ永続化オブジェクト
  #
  def table( tname, pkey = nil )
    return AlPersistMysql2.new( self, tname, pkey )
  end


  ##
  # tableを指定して、Persistオブジェクトを生成 syntax sugar
  #@param  [String]  tname            テーブル名
  #@return [AlPersistMysql2]          データ永続化オブジェクト
  #
  def []( tname )
    return AlPersistMysql2.new( self, tname )
  end

end
