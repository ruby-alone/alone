#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#   Copyright (c) 2010 FAR END Technologies Corporation.
#   Copyright (c) 2025- Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require "test/unit"
require "al_config"
require "al_rdbw_postgres"
require "al_rdbw_sqlite"
require_relative "../param"

##
# RDB wrapper test
#
class AlRdbwTest < Test::Unit::TestCase

  ##
  # 初期化
  #
  def setup()
    File.delete( AlRdbwSqliteTest::DSN ) rescue 0
    @db1 = AlRdbwSqlite.connect( AlRdbwSqliteTest::DSN )
    @db2 = AlRdbwPostgres.connect( AlRdbwPostgresTest::DSN )
  end


  ##
  # 後片付け
  #
  def teardown()
    @db1.close() if @db1
    @db2.close() if @db2
  end


  ##
  # データベースへの接続方法のテスト
  # 別々のDBへ同時接続
  #
  def test_connect1()
    assert_not_equal( @db1, @db2 )

    assert_equal( AlRdbwSqlite, @db1.class )
    assert_equal( AlRdbwPostgres, @db2.class )
  end


  ##
  # アクセステスト
  #
  def test_crud()
    @db1.exec( "create table t1 (id integer, name text);" )

    @db2.exec( "drop table t1;" ) rescue 0
    @db2.exec( "create table t1 (id integer, name text);" )

    res = @db1.insert( "t1", {:id=>1, :name=>"北海道"} )
    assert_equal( res[:cmdtuples], 1 )

    res = @db2.insert( "t1", {:id=>2, :name=>"青森県"} )
    assert_equal( res[:cmdtuples], 1 )

    res = @db2.insert( "t1", {:id=>3, :name=>"岩手県"} )
    assert_equal( res[:cmdtuples], 1 )

    rows = @db1.select( "select * from t1;" )
    assert_equal( rows.count, 1 )

    rows = @db2.select( "select * from t1;" )
    assert_equal( rows.count, 2 )
  end

end
