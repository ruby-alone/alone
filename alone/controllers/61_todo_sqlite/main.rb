#!/usr/bin/env ruby
# alone : application framework for embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2022 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require 'al_form'
require 'al_persist_sqlite'
require 'al_mif'

DB_FILE = "#{AL_TEMPDIR}/todo.db"


class TodoSqliteController < AlController

  ##
  # constructor
  #
  def initialize()
    @form = AlForm.new(
      AlInteger.new("id", foreign:true ),
      AlDate.new("create_date", tag_type:"date", label:"登録日", value:Time.now ),
      AlTextArea.new("memo", label:"ToDoメモ", required:true ),
      AlDate.new("limit_date", tag_type:"date", label:"期限" ),
      AlSubmit.new( "submit1", value:"決定", tag_attr:{style:"float: right;"} )
    )

    # use sqlite3
    @db = AlPersistSqlite.connect( DB_FILE )
    @persist = @db.table( "todo", :id )
  end


  ##
  # デフォルトアクション
  #
  def action_index
    action_list

  rescue =>ex
    if ex.message =~ /^no such table/
      @db.execute( "create table todo ( id integer primary key autoincrement, create_date timestamp, memo text, limit_date timestamp );" )
      retry
    else
      raise ex
    end
  end

end
