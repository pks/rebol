#!/usr/bin/env ruby

require 'nlp_ruby'


def main
  ids = []
  ids = ReadFile.readlines_strip(ARGV[0]).map{ |i| i.strip.to_i } if ARGV[0]
  delete_ids = []
  delete_ids = ReadFile.readlines_strip(ARGV[1]).map{ |i| i.strip.to_i } if ARGV[1]
  i = 0
  while line = STDIN.gets
    puts line if ids.include?(i)&&!delete_ids.include?(i)
    i += 1
  end
end


main

