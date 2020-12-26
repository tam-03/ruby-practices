# frozen_string_literal: true

require 'optparse'

class Wc
  def initialize
    @option = ARGV.getopts('l')
    file = OptionParser.new.parse!(ARGV)
    file.empty? ? @file_or_ipt = Array.new(1, StandardInput.new) : @file_or_ipt = Array.new(file.map {|f| InputtedFile.new(f)})
  end

  def run
    View.new(@file_or_ipt, @option).screen
  end
end

class InputtedFile
  attr_reader :file
  def initialize(file)
    @file = file
  end

  def number_of_lines
    File.read(@file).count("\n")
  end

  def word_count
    open(@file).read.gsub(/\n/, ' ').split(' ').size
  end

  def byte_size
    File.stat(@file).size
  end
end

class StandardInput < InputtedFile
  def initialize
    @standard_input = $stdin.read
  end

  def number_of_lines
    @standard_input.split(/\R/).size
  end

  def word_count
    words = @standard_input.unpack('H*')
    words[0].gsub(/20|0c|0a|0d|09|0b|a0|a0/, ' ').split(' ').size
  end

  def byte_size
    @standard_input.bytesize
  end
end

class View
  def initialize(file_or_ipt, option = nil)
    @option = option
    @file_or_ipt = file_or_ipt
  end

  def screen
    @file_or_ipt.map {|wc| 
      puts "#{space(wc.number_of_lines)} #{space(wc.word_count) unless @option['l']} #{space(wc.byte_size) unless @option['l']} #{space(wc.file) if wc.class == InputtedFile}"
    }
    puts total if @file_or_ipt.size >= 2
  end

  private

  def total
    "#{space(number_of_lines_sum)} #{space(word_count_sum) unless @option['l']} #{space(byte_size_sum) unless @option['l']} total"
  end

  def number_of_lines_sum
    @file_or_ipt.map{ |file| file.number_of_lines}.sum
  end

  def word_count_sum
    @file_or_ipt.map{ |file| file.word_count}.sum
  end

  def byte_size_sum
    @file_or_ipt.map{ |file| file.byte_size}.sum
  end

  def space(int)
    int.to_s.rjust(8)
  end
end

Wc.new.run