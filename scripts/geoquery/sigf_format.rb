#!/usr/bin/env ruby

require 'nlp_ruby'


gold = ReadFile.readlines_strip ARGV[0]
i = -1
while line = STDIN.gets
  i += 1
  line.strip!
  a = [0, 0, 1]
  if line==gold[i]
    a[0] = 1
    a[1] = 1
  elsif line!=''
    a[1] = 1
  end
  puts a.join " "
end

