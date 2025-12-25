#
# alone : application framework for embedded systems.
#         Copyright (c) 2018-2021 Hirohito Higashi All Rights Reserved.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# gettext エミュレーション
#

module AlGetText
  #@return [Hash]  翻訳テーブル {"ja_JP"=>{"orig"=>"trans",...}, ... }
  @@trans_tables = {}

  #@return [String]  カレントロケール
  @@current_locale = defined?(AL_DEFAULT_LOCALE) ? AL_DEFAULT_LOCALE : nil

  #@return [String]  ドメイン名
  @@domain_name = "messages"

  #@return [String]  翻訳ファイルパス
  @@path_mo = nil


  ##
  # load transration file.
  #
  def _load_trans_file()
    if @@path_mo
      file_path = "#{@@path_mo}/#{@@current_locale}/LC_MESSAGES/#{@@domain_name}.mo"
    else
      file_path = "#{AL_BASEDIR}/../locale/#{@@current_locale}/LC_MESSAGES/#{@@domain_name}.mo"
      if !File.exist?(file_path)
        file_path = "#{AL_BASEDIR}/locale/#{@@current_locale}/LC_MESSAGES/#{@@domain_name}.mo"
      end
    end

    # check file exist.
    if !File.exist?(file_path)
      return @@trans_tables[@@current_locale] = {}
    end

    # read the .mo file
    table = {}
    File.open(file_path, "rb") {|f|
      # read header.
      magic, rev, n_strings, orig_tbl_offset, trans_tbl_offset = f.read(20).unpack("L<5")

      # check magic number.
      if magic != 0x950412de
        raise "Invalid MO file '#{file_path}'"
      end

      # read the original and trans table informations.
      orig_descriptors = []
      f.seek(orig_tbl_offset)
      n_strings.times {
        orig_descriptors << f.read(8).unpack("L<2") # [length, offset]
      }

      trans_descriptors = []
      f.seek(trans_tbl_offset)
      n_strings.times {
        trans_descriptors << f.read(8).unpack("L<2") # [length, offset]
      }

      # read actual string.
      n_strings.times {|i|
        f.seek( orig_descriptors[i][1] )
        original_string = f.read( orig_descriptors[i][0] )
        next if original_string.empty?

        f.seek( trans_descriptors[i][1] )
        translated_string = f.read( trans_descriptors[i][0] )

        table[ original_string.force_encoding(Encoding::UTF_8) ] =
          translated_string.force_encoding(Encoding::UTF_8)
      }
    }

    @@trans_tables[@@current_locale] = table
  end

  ##
  # bind text domain
  #
  def bindtextdomain(domain_name, **options)
    @@domain_name = domain_name
    @@path_mo = options[:path]
  end

  ##
  # set the locale
  #
  #@param [String]  locale  ロケール名
  #
  def set_locale( locale )
    @@current_locale = locale
  end

  ##
  # gettext
  #
  def _(s)
    (@@trans_tables[ @@current_locale ] || _load_trans_file())[s] || s
  end

  ##
  # gettext with context
  #
  def p_(msgctxt, s)
    (@@trans_tables[ @@current_locale ] || _load_trans_file())["#{msgctxt}\x04#{s}"] || s
  end

end
