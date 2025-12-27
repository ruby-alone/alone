#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#   Copyright (c) 2021- Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#

require "test/unit"

require_relative "../../alone/al_config.rb"
require "al_main"


def compare_svg( svg, filename )
  dirname = File.dirname(__FILE__)

  if ENV["MAKESVG"]
    File.binwrite( File.join( dirname, filename), svg )
    assert( false, "#{filename} was created." )
    return
  end

  # clipPath の ID を無視して比較する
  flag_ok = true
  File.open( File.join( dirname, filename )) {|file|
    svg.each_line {|s1|
      s2 = file.gets

      if s1.start_with?("<clipPath id=") && s2.start_with?("<clipPath id=")
        next
      end
      if s1.start_with?("<g clip-path=") && s2.start_with?("<g clip-path=")
        next
      end
      if s1 != s2
        flag_ok = false
        break
      end
    }

    if flag_ok && !file.eof?
      flag_ok = false
    end
  }

  if flag_ok
    assert( flag_ok )   # only count assertion success.
  else
    basename = File.basename(filename, ".svg")
    File.binwrite( File.join( dirname, "#{basename}.error.svg" ), svg )
    assert( false, "#{filename} is differ." )
  end
end
