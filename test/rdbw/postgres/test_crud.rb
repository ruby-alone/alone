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
require_relative "../param"


##
# RDB wrapper test for PostgreSQL version
# AlRdbwPostgres クラスのテスト。
#
class AlRdbwPostgresTest < Test::Unit::TestCase

  ##
  # 初期化
  #
  def setup()
    @db = AlRdbw.connect( DSN )
  end


  ##
  # 後片付け
  #
  def teardown()
    @db.close() if @db
  end


  ##
  # テストデータの作成
  #
  def make_testdata()
    @db.execute( "drop table t1;" ) rescue 0
    @db.execute( "create table t1 (id integer, name text);" )

    @db.insert( "t1", {:id=>1, :name=>"北海道"} )
    @db.insert( "t1", {:id=>2, :name=>"青森県"} )
    @db.insert( "t1", {:id=>3, :name=>"岩手県"} )
  end


  ##
  # CRUDテスト
  #
  def test_crud()
    make_testdata()

    # insert
    res = @db.insert( "t1", {:id=>4, :name=>"宮城県"} )
    assert_equal( res[:cmdtuples], 1 )

    # select
    rows = @db.select( "select * from t1 _WHERE_;", {:id=>1} )
    assert_equal( rows, [{:id=>1, :name=>"北海道"}] )
    rows = @db.select( "select * from t1 _WHERE_;", {:id=>111} )
    assert_equal( rows, [] )

    # update
    res = @db.update( "t1", {:name=>"ほっかいどう"}, {:id=>1} )
    assert_equal( res[:cmdtuples], 1 )

    # delete
    res = @db.delete( "t1", {:id=>1} )
    assert_equal( res[:cmdtuples], 1 )
    assert_equal( [{:id=>2, :name=>"青森県"},{:id=>3, :name=>"岩手県"},
                   {:id=>4, :name=>"宮城県"}],
                  @db.select( "select * from t1 order by id;" ))
  end


  ##
  # Hashで取得
  #
  def test_get_hash()
    make_testdata()

    assert_equal( [{:id=>1, :name=>"北海道"},{:id=>2, :name=>"青森県"},
                   {:id=>3, :name=>"岩手県"}],
                  @db.select( "select * from t1 order by id;" ))
    assert_equal( [:id, :name], @db.fields)

    # test empty set
    rows = @db.select( "select * from t1 _WHERE_;", {:id=>111} )
    assert_equal( rows, [] )

    # 不要な操作をしてもエラーにならない事
    assert_equal( nil, @db.select_next())
  end


  ##
  # 配列で取得
  #
  def test_get_array()
    make_testdata()
    @db.select_data_type = :ARRAY

    assert_equal( [[1, "北海道"],[2, "青森県"],[3, "岩手県"]],
                  @db.select( "select * from t1 order by id;" ))
    assert_equal( [:id, :name], @db.fields)

    # test empty set
    rows = @db.select( "select * from t1 _WHERE_;", {:id=>111} )
    assert_equal( rows, [] )

    # 不要な操作をしてもエラーにならない事
    assert_equal( nil, @db.select_next())
  end


  ##
  # 1行ずつHashで取得
  #
  def test_get_hash_row()
    make_testdata()
    @db.select_fetch_mode = :ROW

    assert_equal( {:id=>1, :name=>"北海道"},
                  @db.select( "select * from t1 order by id;" ))
    assert_equal( [:id, :name], @db.fields )

    assert_equal( {:id=>2, :name=>"青森県"}, @db.select_next())
    assert_equal( {:id=>3, :name=>"岩手県"}, @db.select_next())
    assert_equal( nil, @db.select_next())
    assert_equal( nil, @db.select_next())
  end


  ##
  # 1行ずつArrayで取得
  #
  def test_get_array_row()
    make_testdata()
    @db.select_fetch_mode = :ROW
    @db.select_data_type = :ARRAY

    assert_equal( [1, "北海道"],
                  @db.select( "select * from t1 order by id;" ))
    assert_equal( [:id, :name], @db.fields )

    assert_equal( [2, "青森県"], @db.select_next())
    assert_equal( [3, "岩手県"], @db.select_next())
    assert_equal( nil, @db.select_next())
    assert_equal( nil, @db.select_next())
  end

end
