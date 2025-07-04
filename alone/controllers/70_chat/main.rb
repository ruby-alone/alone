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

require "al_form"
require "al_template"
require "al_worker_ipc"


class AlController
  include AlWorker::IpcAction

  ##
  # constructor
  #
  def initialize()
    @ipc = AlWorker::Ipc.open( "/tmp/chat_server" )
  rescue Errno::ENOENT
    run_server()
  end


  ##
  # サーバー起動
  #
  def run_server()
    require 'rbconfig'
    ruby = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name']) + RbConfig::CONFIG['EXEEXT']
    spawn( ruby, "-I#{AL_BASEDIR}", "chat_server.rb", :pgroup=>0 )
    10.times do
      sleep 1
      begin
        @ipc = AlWorker::Ipc.open( "/tmp/chat_server" )
        break
      rescue Errno::ENOENT
        # retry
      end
    end

    raise "Error. Chat server cannot start."  if ! @ipc
  end


  ##
  # デフォルトアクション
  #
  def action_index()
    AlTemplate.run( './index.rhtml' )
  end

end
