#!/usr/bin/env ruby
#
# JavaScript 用 gettext 対象文字列抽出
#
# 動作概要
#  * JavaScriptソースから、_("...") 文字列を取り出しターゲットファイルを作る
#  * ターゲットファイルが既にあれば、マージ相当の動作をする
#
# ターゲットファイル
#  htdocs/locale/ja_JP/messages.js
#
# Usage
#  make_js_gettext.rb -o OutputFile InputFiles...
#
# Workflow example.
#  make_js_gettext.rb -o htdocs/locale/ja_JP/messages.js htdocs/js/*.js
#  edit htdocs/locale/ja_JP/messages.js
#
# Note
#  gettext で言うところの、.pot(template) .po は作らない。
#

require "optparse"
require "stringio"
begin
  require "nokogiri"
  $flag_nokogiri_ok = true
rescue LoadError
  $flag_nokogiri_ok = false
end

# 翻訳対象文字列抽出用正規表現
RX_DQSTR = /_\(\s*"((?:[^\\"]+|\\.)*)"\s*\)/    #  _("...")
RX_SQSTR = /_\(\s*'((?:[^\\']+|\\.)*)'\s*\)/    #  _('...')


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
#@return [Hash<Array>]    パース結果
#
#(note)
# 正規表現による簡易的なパースによって抽出している。
#
# 結果フォーマット
#  * メッセージをキーとしたHash
#  * 値はHash {filename:, lineno:} の配列
#  { "message1": [{filename:"...", lineno:n}],
#    "message2": [{filename:"...", lineno:n},
#                 {filename:"...", lineno:n},...],
#  }
#
def extract_trans_strings( source_files )
  ret = {}

  # すべてのファイルを読んで、対象文字列を抽出する
  source_files.each {|filename|
    vp("Target file: #{filename}", 2)

    case File.extname( filename )
    when ".js"
      res = extract_from_js_file( filename )

    when ".rhtml", ".html"
      res = extract_from_html_file( filename )

    else
      STDERR.puts "Error: Illegal file (extension). #{filename}"
      exit 1
    end

    # 戻り値の仕様に整形
    res.each {|lineno, message|
      ret[ message ] ||= []
      ret[ message ] << {filename:filename, lineno:lineno}
    }
  }

  return ret

rescue Errno::ENOENT, Errno::EACCES =>ex
  puts ex.message
  exit
end


##
# JavaScriptファイルから翻訳対象文字列の抽出
#
#@param  [String]       filename    ソースファイル名
#@return [Array<Array>]             結果
#
# 結果フォーマット [行番号, メッセージ] の配列
#  [ [3, "Hello world."],
#    [9, "Another world."],
#  ]
#
def extract_from_js_file( filename )
  file = File.open( filename )
  ret = []
  flag_v = ($opts[:v] == 1)

  while txt = file.gets
    pos = 0
    while match = RX_DQSTR.match( txt, pos )
      if flag_v; vp("Target file: #{filename}"); flag_v = false; end
      vp("Found target string: #{file.lineno}:\"#{match[1]}\"", 2)
      pos = match.end(1) + 1
      ret << [file.lineno, match[1]]
    end
    pos = 0
    while match = RX_SQSTR.match( txt, pos )
      if flag_v; vp("Target file: #{filename}"); flag_v = false; end
      vp("Found target string: #{file.lineno}:\"#{match[1]}\"", 2)
      pos = match.end(1) + 1
      ret << [file.lineno, match[1].gsub('"', '\\"')]
    end
  end

  file.close
  return ret
end


##
# (r)htmlファイルの<script>タグから、翻訳対象文字列の抽出
#
#@param  [String]       filename    ソースファイル名
#@return [Array<Array>]             結果
#
def extract_from_html_file( filename )
  if !$flag_nokogiri_ok
    STDERR.puts 'Error: require "nokogiri" rubygem.'
    exit 1
  end

  htmldoc = Nokogiri::HTML( File.read( filename ))
  ret = []
  flag_v = ($opts[:v] == 1)

  htmldoc.css("script").each {|script_node|
    file = StringIO.new( script_node.inner_html )
    while  txt = file.gets
      pos = 0
      while match = RX_DQSTR.match( txt, pos )
        lineno = script_node.line + file.lineno - 1
        pos = match.end(1) + 1
        if flag_v; vp("Target file: #{filename}"); flag_v = false; end
        vp("Found target string: #{lineno}:\"#{match[1]}\"", 2)
        ret << [lineno, match[1]]
      end
      pos = 0
      while match = RX_SQSTR.match( txt, pos )
        lineno = script_node.line + file.lineno - 1
        pos = match.end(1) + 1
        if flag_v; vp("Target file: #{filename}"); flag_v = false; end
        vp("Found target string: #{lineno}:\"#{match[1]}\"", 2)
        ret << [lineno, match[1].gsub('"', '\\"')]
      end
    end

    file.close
  }

  return ret
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
    break  if !flag_continue

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
        STDERR.puts "Error: Illegal data exists. #{filename}:#{file.lineno}"
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
#@param [Hash<Array>]   mo_data   read_exist_message() の出力
#
def output_trans_data( filename, po_data, mo_data )
  vp("Write file: #{filename}")
  mo_data ||= {}
  file = (filename == "-") ? STDOUT : File.open( filename, "w" )
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
      file.write("  // #{file1[:filename]}:#{file1[:lineno]}\n")
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
  file.close
end



##
# main
#
$opts = get_options()
exit if !$opts

source_files = ARGV
if source_files.empty?
  STDERR.puts "Error: File not given."
  exit 1
end
out_filename = $opts[:out_file] || "-"

# 翻訳対象文字列の抽出
po_data = extract_trans_strings( source_files )

# 翻訳済みファイルが既にあれば読み込む
if out_filename != "-" && File.exist?(out_filename)
  mo_data = read_exist_message( out_filename )
end

# 結果の出力
output_trans_data( out_filename, po_data, mo_data )
