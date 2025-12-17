#!/usr/bin/env ruby
# alone : application framework for embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2025 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require 'al_form'
require 'al_persist_mysql2'
require 'al_mif'

DSN = {host:"localhost", database:"al_testdb1", username:"al_user1", password:"al_pass1"}

class TodoMysqlController < AlController

  ##
  # constructor
  #
  def initialize()
    @form = AlForm.new(
      AlInteger.new("id", foreign:true ),
      AlDate.new("create_date", tag_type:"date", label:"登録日", value:Time.now ),
      AlTextArea.new("memo", label:"ToDoメモ", required:true ),
      AlDate.new("limit_date", tag_type:"date", label:"期限" ),
      AlSubmit.new("submit1", value:"決定", tag_attr:{style:"float: right;"} )
    )

    # use mysql
    @db = AlPersistMysql2.connect( DSN )
    @persist = @db.table("todo", :id )
  end


  ##
  # デフォルトアクション
  #
  def action_index
    action_list

  rescue Mysql2::Error =>ex
    puts Alone.escape_html_br(ex.message) + "<br><br>"
    puts "Create table first.<br>"
    puts "<pre>"
    puts "create table todo ( id serial, create_date date, memo text, limit_date date );<br>"
    puts "DSN #{DSN.to_s}<br>"
    puts "</pre>"
  end

end
