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
require "al_rdbw_mysql2"
require_relative "../param"


##
# RDB wrapper test for MySQL2 version.
# AlRdbwMysql2クラスのテスト。
#
class AlRdbwMysql2Test < Test::Unit::TestCase

  ##
  # 後片付け
  #
  def teardown()
    @db1.close() if @db1
    @db2.close() if @db2
    @db3.close() if @db3
  end


  ##
  # requreされたファイルごとに適したコネクションメソッドを利用し、
  # オブジェクトができることを確認。
  #
  def test_connect1()
    @db1 = AlRdbw.connect( DSN )
    assert_equal( @db1.class, AlRdbwMysql2 )
  end


  ##
  # 同じ接続情報を使うと、同じ同じオブジェクトを返す。
  # （複数接続の抑制）
  #
  def test_connect2()
    @db1 = AlRdbw.connect( DSN )
    @db2 = AlRdbw.connect( DSN )
    assert_equal( @db1, @db2 )

    @db3 = AlRdbwMysql2.connect( DSN )
    assert_equal( @db1, @db3 )
  end


  ##
  # 一度接続をするとデフォルト接続として扱われ、接続情報が不要になる。
  def test_connect3()
    @db1 = AlRdbw.connect( DSN )
    @db2 = AlRdbw.connect()
    assert_equal( @db1, @db2 )

    @db3 = AlRdbwMysql2.connect( DSN )
    assert_equal( @db1, @db3 )
  end


  ##
  # 違うサーバや違うユーザで接続すると、それに対応した新しい接続が開始され、
  # 新たなオブジェクトが返る
  #
  def test_connect4()
    @db1 = AlRdbw.connect( DSN )
    @db2 = AlRdbw.connect( DSN2 )
    assert_not_equal( @db1, @db2 )
  end

end
