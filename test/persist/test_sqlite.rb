#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#   Copyright (c) 2025- Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require "test/unit"
require "al_config"
require "al_persist_sqlite"
#require_relative "../param"

DSN = "/tmp/testdb.sqlite"

##
# Data Persist test for SQLite version.
# AlPersist::Sqlite のテスト
#
class AlPersistSqliteTest < Test::Unit::TestCase

  ##
  # 初期化
  #
  def setup()
    File.delete( DSN ) rescue 0
    @db = AlPersist::Sqlite.connect( DSN )
  end

  ##
  # 後片付け
  #
  def teardown()
    if @db
      @db.execute("drop table t1;") rescue 0
      @db.close()
    end
  end


  ##
  # テストデータの作成 1
  #
  def make_testdata1()
    @db.execute("create table t1 (id integer primary key, name text, area float, region integer);")

    @db.insert("t1", {id:1, name:"北海道", area:83422.27, region:1})
    @db.insert("t1", {id:2, name:"青森県", area:9645.11,  region:2})
    @db.insert("t1", {id:3, name:"岩手県", area:15275.05, region:2})

    @t1 = @db.table("t1", :id)
  end


  ##
  # all メソッドのテスト
  #
  def test_method_all()
    make_testdata1()

    res = @t1.all
    assert_equal( 3, res.count )
    assert_equal( AlPersist::Sqlite, res[0].class )

    @db.execute("delete from t1;")
    res = @t1.all
    assert_equal( [], res )
  end


  ##
  # create メソッドのテスト
  #
  def test_method_create()
    make_testdata1()

    # 引数の指定があれば、その値を一旦内部値(@values)にしたうえで、内部値を新規保存する。
    assert_equal( {}, @t1.values )
    assert_equal( true, @t1.create({id:4, name:"宮城県"}) )
    assert_equal( {id:4, name:"宮城県"}, @t1.values )
    assert_equal( 4, @t1.all.count );

    # キーをあらかじめセットしてから実行する場合
    @t1[:id] = 5
    @t1[:name] = "秋田県"
    assert_equal( true, @t1.create() )
    assert_equal( 5, @t1.all.count );

    # 登録確認
    check = [1,2,3,4,5]
    @t1.all.each {|r|
      check.delete( r[:id] )
    }
    assert( check.empty? )

    # プライマリキー重複テスト
    assert_raise() { @t1.create({ id:1, name:"Hokkaido"}) }
  end


  ##
  # delete メソッドのテスト
  #
  def test_method_delete()
    make_testdata1()

    # キーの合致するRDB内のデータを、削除する。
    assert_equal( true,   @t1.delete({id:1}) )
    assert_equal( false,  @t1.delete({id:1}) )
    assert_equal( false,  @t1.delete({id:999}) )
    assert_equal( 2, @t1.all.count );

    # valuesには、プライマリキー以外の値が含まれていてもよく、単に無視される。
    assert_equal( true,  @t1.delete({id:2, name:"UNKNOWN", unknown:"UNKNOWN"}) )

    # 引数の指定があれば、その値を一旦内部値(@values)にしたうえで削除する。
    assert_equal( 2, @t1[:id] )
    assert_equal( 1, @t1.all.count );

    # キーをあらかじめセットしてから実行する場合
    @t1[:id] = 3
    assert_equal( true, @t1.delete() )
    assert_equal( 0, @t1.all.count );
  end


  ##
  # entry メソッドのテスト
  #
  def test_method_entry()
    make_testdata1()

    # キーの合致するデータがあれば更新し、なければ新規登録する。
    # 引数の指定があれば、その値を一旦内部値(@values)にしたうえで登録する。
    assert_equal( true, @t1.entry({ id:2, name:"AOMORI" }) )
    assert_equal( 3, @t1.all.count );

    assert_equal( true, @t1.entry({ id:4, name:"MIYAGI" }) )
    assert_equal( 4, @t1[:id] )
    assert_equal( "MIYAGI", @t1[:name] )
    assert_equal( 4, @t1.all.count );

    # キーをあらかじめセットしてから実行する場合
    @t1[:id] = 5
    @t1[:name] = "秋田県"
    assert_equal( true, @t1.entry() )
    assert_equal( 5, @t1.all.count );
  end


  ##
  # read メソッドのテスト
  #
  def test_method_read()
    make_testdata1()

    assert_equal( true, @t1.read({ id:2 }) )
    assert_equal( 2, @t1[:id] )
    assert_equal( "青森県", @t1[:name] )

    assert_equal( false, @t1.read({ id:999 }) )

    @t1[:id] = 3
    assert_equal( true, @t1.read() )
    assert_equal( 3, @t1[:id] )
    assert_equal( "岩手県", @t1[:name] )
  end


  ##
  # search メソッドのテスト
  #
  def test_method_search()
    make_testdata1()

    # データ1件を1つのAlPersistオブジェクトとして配列で返す
    res = @t1.search()
    assert_equal( 3, res.count )

    # 自分は何も変わらず、自分の複製を生産する。
    assert_equal( nil, @t1[:name] )

    # 一件もデータがない場合は、空の配列を返す。
    res = @t1.search( :where=>{id:999})
    assert_equal( [], res )

    # :total_rowsがtrueの時は、全件数も取得する。
    res = @t1.search( :total_rows=>true )
    assert_equal( 3, res[0].search_condition[:total_rows] )

    # :total_rowsが数値の時は、それを全件数の値として採用する。
    res = @t1.search( :total_rows=>99 )
    assert_equal( 99, res[0].search_condition[:total_rows] )

    # :limit 指定
    assert_equal( 1, @t1.search( :limit=>1 ).count )
    assert_equal( 3, @t1.search( :limit=>99 ).count )

    # :order_by 指定
    res = @t1.search( :order_by=>"area" )
    assert_equal( [2,3,1], [res[0][:id], res[1][:id], res[2][:id]] )
    res = @t1.search( :order_by=>"area desc" )
    assert_equal( [1,3,2], [res[0][:id], res[1][:id], res[2][:id]] )
    res = @t1.search( :order_by=>["region", "area"] )
    assert_equal( [1,2,3], [res[0][:id], res[1][:id], res[2][:id]] )
    res = @t1.search( :order_by=>{ region:"asc", area:"desc" } )
    assert_equal( [1,3,2], [res[0][:id], res[1][:id], res[2][:id]] )

    # :offset 指定
    res = @t1.search( :order_by=>"id", :limit=>1, :offset=>1 )
    assert_equal( 2, res[0][:id] )
    assert_equal( 0, @t1.get_previous_offset() )
    assert_equal( 2, @t1.get_next_offset() )

    # where条件のテスト
    res = @t1.search( :where=>{id:2})
    assert_equal( 1, res.count )
    assert_equal( "青森県", res[0][:name] )

    res = @t1.search( :where=>{region:2, id:3} )
    assert_equal( 1, res.count )
    assert_equal( "岩手県", res[0][:name] )

    res = @t1.search( :where=>{"area >"=>20000} )
    assert_equal( 1, res.count )
    assert_equal( "北海道", res[0][:name] )

    res = @t1.search( :where=>{"name like"=>"%県"} )
    assert_equal( 2, res.count )
  end


  ##
  # update メソッドのテスト
  #
  def test_method_update()
    make_testdata1()

    assert_equal( true,  @t1.update({ id:2, name:"AOMORI" }) )
    assert_equal( false, @t1.update({ id:4, name:"MIYAGI" }) )

    res = @t1.all.sort_by {|t1| t1[:id] }
    assert_equal( 3, res.count );
    assert_equal( "AOMORI", res[1][:name] )
  end

end
