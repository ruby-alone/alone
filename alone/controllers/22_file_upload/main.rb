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

require 'alone'
require 'base64'

class FileUploadController < AlController

  #
  # constructor
  #
  def initialize()
    @form = AlForm.new(
      AlFile.new("file1", label:"画像ファイル", required: true),
      AlSubmit.new("submit1", value:"決定",
                   tag_attr:{:style=>"float: right;"})
    )
    @form.tag_attr[:enctype] = "multipart/form-data"
    @form.action = Alone.make_uri(action:"upload")
  end


  #
  # デフォルトアクション
  #
  def action_index()
    AlTemplate.run( 'index.rhtml' )
  end


  #
  # アップロード
  #
  def action_upload()
    if !@form.validate()
      AlTemplate.run( 'index.rhtml' )
      return
    end

    @image = {}
    @image[:content_type] = @form[:file1][:content_type]
    image_data = File.read(@form[:file1][:tmp_name])
    @image[:data] = Base64.encode64( image_data )

    AlTemplate.run( 'index.rhtml' )
  end
end
