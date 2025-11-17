#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# alone : application framework for embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2022 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2022 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require 'al_form'
require 'al_persist_file'
require 'al_mif'

DB_FILE = "#{AL_TEMPDIR}/todo.txt"


class TodoFileController < AlController

  ##
  # constructor
  #
  def initialize()
    @form = AlForm.new(
      AlInteger.new("id", foreign:true ),
      AlDate.new("create_date", tag_type:"date", label:"登録日", value:Time.now ),
#      AlRadios.new("priority", label:"優先度",
#        options:{ r1:"急ぎ", r2:"普通", r3:"低い" }, required:true ),
      AlTextArea.new("memo", label:"ToDoメモ", required:true ),
      AlDate.new("limit_date", tag_type:"date", label:"期限" ),
      AlSubmit.new("submit1", value:"決定", tag_attr:{style:"float: right;"} )
    )

    # use file
    @persist = AlPersistFile.connect( DB_FILE )
  end


  ##
  # デフォルトアクション
  #
  alias action_index action_list

end
