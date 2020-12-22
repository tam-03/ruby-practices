# frozen_string_literal: true

require 'optparse'
require 'etc'

class Ls

  def initialize(command = Command.new)
    @command = command
    @files = Dir.entries('.').sort - Dir['.*']
    @files = Dir.entries('.').sort if @command.a_option
    @files.reverse! if @command.r_option
  end

  def print
    @command.l_option ? Print.new(@files).list : Print.new(@files).horizontal
  end

  def self.file_detail(files)
    files.map { |file| FileDetail.new(file) }
  end

  def self.files_str_max_length(files)
    files.map { |file| FileDetail.new(file).file_length }.max
  end

  def self.block_total(files)
    files.map { |file| FileDetail.new(file).block }.sum
  end

end

class Print
  def initialize(files)
    @files = files
  end

  def horizontal
    str_max_length = Ls.files_str_max_length(@files) + 2
    (0..6).map do |num|
      lines = []
      Ls.file_detail(@files).each_slice(7) { |files| lines << files[num] }
      lines.map do |file|
        print file.to_s.ljust(str_max_length)
      end
      puts "\n"
    end
  end

  def list
    puts " total #{Ls.block_total(@files)}"
    Ls.file_detail(@files).each do |file|
      print file.type
      print file.permission
      print "#{file.link.rjust(3)} "
      print "#{file.uid_name} "
      print "#{file.gid_name} "
      print "#{file.size.to_s.rjust(5)} "
      print file.update_day
      puts file.to_s
    end
  end
end

class FileDetail
  def initialize(file)
    @file = file
  end

  def type
    type = File.ftype(@file)
    {
      "file": '-',
      "directory": 'd',
      "link": 'l'
    }[type.to_sym]
  end

  def permission
    format('%o', File.stat(@file).world_readable?).chars.map { |pms|
      {
        "7": 'rwx',
        "6": 'rw-',
        "5": 'r-x',
        "4": 'r--',
        "3": '-wx',
        "2": '-w-',
        "1": '--x'
      }[pms.to_sym]
    }.join
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

  def to_s
    @file
  end
end

class Command
  def initialize(command = ARGV.getopts('arl'))
    @command = command
  end

  def a_option
    @command['a']
  end

  def r_option
    @command['r']
  end

  def l_option
    @command['l']
  end
end

Ls.new.print
