#!/usr/bin/env ruby
#
#
#
#
# 動作概要
#  * JavaScriptソースから、_("...") 文字列を取り出しターゲットファイルを作る
#  * ターゲットファイルが既にあれば、マージ相当の動作をする
#
# ターゲットファイル
#  htdocs/locale/ja_JP/messages.js
#
# Usage
#  make_js_gettext.rb -o htdocs/locale/ja_JP/messages.js htdocs/js/*.js
#

require "optparse"

##
# verbose print
#
def vp( s, level = 1 )
  STDERR.puts s  if $opts[:v] >= level
end


##
# parse command line option
#
def get_options
  ret = {v:0}

  opt = OptionParser.new
  opt.on("-o output file") {|v| ret[:out_file] = v }
  opt.on("-v", "--verbose", "verbose mode") {|v| ret[:v] += 1 }
  opt.parse!(ARGV)
  return ret

rescue OptionParser::MissingArgument =>ex
  STDERR.puts ex.message
  return nil
end


##
# 翻訳対象文字列の抽出
#
#@param  [Array<String>]  source_files   ファイル名の配列
#@return [Hash<Array>]    パース結果 {"key_str": [{name:"...", lineno:n},...]}
#
#(note)
# 正規表現による簡易的なパースによって抽出している。
#
def extract_trans_strings( source_files )
  rx_dqstr = /_\(\s*"((?:[^\\"]+|\\.)*)"\s*\)/
  rx_sqstr = /_\(\s*'((?:[^\\']+|\\.)*)'\s*\)/
  ret = {}

  # すべてのファイルを読んで、対象文字列を抽出する
  source_files.each {|filename|
    vp("Target: #{filename}")
    file = File.open(filename)
    while txt = file.gets
      pos = 0
      while match = rx_dqstr.match( txt, pos )
        vp("Found target string: \"#{match[1]}\"", 2)
        pos = match.end(1) + 1
        ret[ match[1] ] ||= []
        ret[ match[1] ] << {name:filename, lineno:file.lineno}
      end
      pos = 0
      while match = rx_sqstr.match( txt, pos )
        vp("Found target string: \"#{match[1]}\"", 2)
        pos = match.end(1) + 1
        key = match[1].gsub('"', '\\"')
        ret[ key ] ||= []
        ret[ key ] << {name:filename, lineno:file.lineno}
      end
    end
    file.close
  }

  return ret

rescue Errno::ENOENT, Errno::EACCES =>ex
  puts ex.message
  exit
end


##
# 既存messagesファイルの読み込み
#
#@param  [String]  filename     filename
#@return [Hash]                 result {"key_str":"trans_str", ...}
#
#(note)
# expected data file structure is
#```
# var AL_LC_MESSAGES = {
#   // path/to/file1.js:123
#   "Hello world.": "こんにちは、世界",
#   ...
# };
#```
def read_exist_message( filename )
  vp("Read an existing message file: #{filename}")
  ret = {}

  File.open( filename ) {|file|
    flag_continue = false

    # ヘッダ部読み捨て
    while txt = file.gets
      if txt.start_with?("var AL_LC_MESSAGES = {")
        flag_continue = true
        break
      end
    end
    return ret  if !flag_continue

    # データ部読み込み
    while txt = file.gets
      txt.chomp!
      case txt
      when /^\s*(\/\/.*)?$/
        # skip.

      when /"((?:[^\\"]+|\\.)*)":\s*(.+)$/
        vp("Read: #{$1}: #{$2}", 2)
        ret[$1] = $2

      when /^};/
        break

      else
        raise "Illegal data exists. #{filename}:#{file.lineno}"
      end
    end
  }

  return ret
end


##
# 結果の出力
#
#@param [String]        filename  出力ファイル名
#@param [Hash<Array>]   po_data   extract_trans_strings() の出力
#
def output_trans_data( filename, po_data )
  # 翻訳済みファイルが既にあれば読み込む
  mo_data = File.exist?(filename) ? read_exist_message( filename ) : {}

  # 書き出す
  vp("Write file: #{filename}")
  File.open( filename, "w" ) {|file|
    file.write <<EOS
/*
  Auto generated language translation data.

  how to edit.
   1. Find the target message.
   2. Replace the following colon-separated string with the translation.
*/

var AL_LC_MESSAGES = {
EOS
    po_data.each {|key_str,files|
      trans_str = mo_data[key_str] || '"",'

      files.each {|file1|
        file.write("  // #{file1[:name]}:#{file1[:lineno]}\n")
      }
      file.write(%Q(  "#{key_str}": #{trans_str}\n\n))
    }

    # 既存ファイルに有るが、JSコードには無いものをまとめて書き出し
    obsolete_keys = mo_data.keys - po_data.keys
    if !obsolete_keys.empty?
      file.write("  // obsolete?\n")
      obsolete_keys.each {|key_str|
        file.write(%Q(  "#{key_str}": #{mo_data[key_str]}\n))
      }
    end

    file.write("};\n")
  }
end



##
# main
#
$opts = get_options()
exit if !$opts

source_files = ARGV
if source_files.empty?
  STDERR.puts "File not given."
  exit 1
end

po_data = extract_trans_strings( source_files )
output_trans_data( $opts[:out_file], po_data )
