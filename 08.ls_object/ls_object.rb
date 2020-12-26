# frozen_string_literal: true

require 'optparse'
require 'etc'

class Ls
  def initialize(option = Option.new)
    @option = option
    @files = Dir.entries('.').sort - Dir['.*']
    @files = Dir.entries('.').sort if @option.a_option
    @files.reverse! if @option.r_option
  end

  def print
    @option.l_option ? Print.new(@files).list : Print.new(@files).horizontal
  end
end

class Print
  def initialize(files)
    @files = files
  end

  def horizontal
    str_max_length = files_str_max_length + 2
    (0..5).map do |num|
      lines = []
      file_detail.each_slice(6) { |file| lines << file[num] }
      lines.map do |file|
        print file.file.ljust(str_max_length) unless file.nil?
      end
      puts "\n"
    end
  end

  def list
    puts " total #{block_total}"
    file_detail.each do |file|
      print file.type
      print file.permission
      print "#{file.link.rjust(3)} "
      print "#{file.uid_name} "
      print "#{file.gid_name} "
      print "#{file.size.to_s.rjust(5)} "
      print file.update_day
      puts file.file
    end
  end

  private

  def file_detail
    @files.map { |file| FileDetail.new(file) }
  end

  def files_str_max_length
    @files.map { |file| FileDetail.new(file).file_length }.max
  end

  def block_total
    @files.map { |file| FileDetail.new(file).block }.sum
  end
end

class FileDetail
  attr_reader :file

  def initialize(file)
    @file = file
  end

  def type
    {
      "file": '-',
      "directory": 'd',
      "link": 'l'
    }[File.ftype(@file).to_sym]
  end

  def permission
    format('%o', File.stat(@file).world_readable?).chars.map { |pms| str_permission_convert(pms) }.join
  end

  def link
    File.stat(@file).nlink.to_s
  end

  def uid_name
    Etc.getpwuid(File.stat(@file).uid).name
  end

  def gid_name
    Etc.getgrgid(File.stat(@file).gid).name
  end

  def size
    File.stat(@file).size
  end

  def update_day
    mtime = File.stat(@file).mtime
    mtime_a = mtime.to_a
    mtime_s = mtime.strftime('%R')
    (mtime_a[4].to_s.rjust(2) + mtime_a[3].to_s.rjust(3)).to_s + ' ' + mtime_s + ' '
  end

  def file_length
    @file.size
  end

  def block
    File.stat(@file).blocks
  end

  private

  def str_permission_convert(int)
    {
      "7": 'rwx',
      "6": 'rw-',
      "5": 'r-x',
      "4": 'r--',
      "3": '-wx',
      "2": '-w-',
      "1": '--x'
    }[int.to_sym]
  end
end

class Option
  def initialize(option = ARGV.getopts('arl'))
    @option = option
  end

  def a_option
    @option['a']
  end

  def r_option
    @option['r']
  end

  def l_option
    @option['l']
  end
end

Ls.new.print
