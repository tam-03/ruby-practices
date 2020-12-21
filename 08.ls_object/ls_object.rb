# frozen_string_literal: true
require 'optparse'
require 'etc'

class Ls

  def initialize(command)
    @files = Ls.get_file(command)
  end

  def self.get_file(command)
    file_array = Dir.entries('.').sort - Dir['.*']
    file_array = Dir.entries('.').sort if command.a_option
    file_array.reverse! if command.r_option
    file_array
  end

  def file_detail
    @files.map{ |file| FileDetail.new(file)}
  end

  def files_str_max_length
    @files.map{ |file| FileDetail.new(file).file_length}.max
  end

  def block_total
    @files.map { |file| FileDetail.new(file).block }.sum
  end

end

class Print
  def initialize(files)
    @files = files
  end

  def horizontal
    str_max_length = @files.files_str_max_length + 2
    (0..6).map { |num|
      lines = []
      @files.file_detail.each_slice(7) { |files|
        lines << files[num]
      }
      lines.map { |file|
        print file.to_s.ljust(str_max_length)
      }
      puts "\n"
    }
  end

  def list
    puts " total #{@files.block_total}"
    @files.file_detail.each { |file|
      print file.type
      print file.parmission
      print "#{file.link} "
      print "#{file.uid_name} "
      print "#{file.gid_name} "
      print "#{file.size.to_s.rjust(5)} "
      print file.update_day
      puts file.to_s
    }
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
    }[:"#{type}"]
  end

  def parmission
    mode = File.stat(@file).world_readable?
    parmission = format('%o', mode)
    pms = parmission.to_s.split(//).to_a
    (0..2).each do |i|
      pms[i] = {
        "7": 'rwx',
        "6": 'rw-',
        "5": 'r-x',
        "4": 'r--',
        "3": '-wx',
        "2": '-w-',
        "1": '--x'
      }[:"#{pms[i]}"]
      return pms.join if i == 2
    end
  end

  def link
    file_link = File.stat(@file).nlink.to_s
    file_link.rjust(3).to_s
  end

  def uid_name
    Etc.getpwuid(File.stat(@file).uid).name
  end

  def gid_name
    Etc.getgrgid(File.stat(@file).gid).name
  end

  def size
    file_size = File.stat(@file).size
  end

  def update_day
    mtime = File.stat(@file).mtime
    mtime_a = mtime.to_a
    mtime_s = mtime.strftime('%R')
    (mtime_a[4].to_s.rjust(2) + mtime_a[3].to_s.rjust(3)).to_s + ' ' + mtime_s + ' '
    # monthを文字列に変更
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
   return @command["a"]
  end

  def r_option
   return @command["r"]
  end

  def l_option
   return @command["l"]
  end
end

command = Command.new
files = Ls.new(command)
command.l_option ? Print.new(files).list : Print.new(files).horizontal
