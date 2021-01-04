# frozen_string_literal: true

require 'optparse'

class Main
  def initialize
    @option = ARGV.getopts('l')
    file = OptionParser.new.parse!(ARGV)
    @files_or_stdins = file.empty? ? Array.new(1, StandardInput.new) : Array.new(file.map { |f| InputFile.new(f) })
  end

  def run
    View.new(@files_or_stdins, @option).output
  end
end

class InputFile
  attr_reader :file
  def initialize(file)
    @file = file
  end

  def number_of_lines
    File.read(@file).count("\n")
  end

  def word_count
    File.open(@file).read.tr("\n", ' ').split(' ').size
  end

  def byte_size
    File.stat(@file).size
  end
end

class StandardInput
  def initialize
    @standard_input = $stdin.read
  end

  def number_of_lines
    @standard_input.split(/\R/).size
  end

  def word_count
    words = @standard_input.unpack('H*')
    words[0].gsub(/20|0c|0a|0d|09|0b|a0/, ' ').split(' ').size
  end

  def byte_size
    @standard_input.bytesize
  end
end

class View
  def initialize(files_or_stdins, option = nil)
    @option = option
    @files_or_stdins = files_or_stdins
  end

  def output
    @files_or_stdins.map do |wc|
      puts "#{space(wc.number_of_lines)} #{space(wc.word_count) unless @option['l']} #{space(wc.byte_size) unless @option['l']} #{space(wc.file) if wc.class == InputFile}"
    end
    puts total_text if @files_or_stdins.size >= 2
  end

  private

  def total_text
    "#{space(total_number_of_lines)} #{space(total_word_count) unless @option['l']} #{space(total_byte_size) unless @option['l']} total"
  end

  def total_number_of_lines
    @files_or_stdins.sum(&:number_of_lines)
  end

  def total_word_count
    @files_or_stdins.sum(&:word_count)
  end

  def total_byte_size
    @files_or_stdins.sum(&:byte_size)
  end

  def space(int)
    int.to_s.rjust(8)
  end
end

Main.new.run
