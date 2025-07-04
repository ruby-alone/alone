#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# alone : application framework for small embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2022 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the COPYRIGHT file.
#

require 'al_form'
require 'al_persist_postgres'
require 'al_mif'

DSN = {host:"localhost", dbname:"al_testdb1",
       user:"al_user1", password:"al_pass1"}

class TodoPostgresController < AlController

  ##
  # constructor
  #
  def initialize()
    @form = AlForm.new(
      AlInteger.new( "id", foreign:true ),
      AlDate.new( "create_date", label:"登録日", value:Time.now ),
      AlTextArea.new( "memo", label:"ToDoメモ", required:true ),
      AlDate.new( "limit_date", label:"期限" ),
      AlSubmit.new( "submit1", value:"決定", tag_attr:{style:"float: right;"} )
    )

    # use postgresql
    @db = AlPersistPostgres.connect( DSN )
    @persist = @db.table( "todo", :id )
  end


  ##
  # デフォルトアクション
  #
  def action_index
    action_list

  rescue PG::Error=>ex
    puts Alone.escape_html(ex.message) + "<br><br>"
    puts "Create table first.<br>"
    puts "create table todo ( id serial primary key, create_date date, memo text, limit_date date );<br>"
    puts "DSN #{DSN.to_s}<br>"
  end

end
