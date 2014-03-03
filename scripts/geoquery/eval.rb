#!/usr/bin/env ruby

require 'nlp_ruby'


gold = ReadFile.readlines_strip ARGV[0]
i = j = correct = 0
while line = STDIN.gets
  line.strip!
  correct += 1 if line==gold[i]
  i += 1
  j += 1 if line=='' # no parse
end
acc = correct.to_f/i
prec = correct.to_f/(i-j)
puts "acc=#{(100*acc).round 2} prec=#{(100*prec).round 2} (#{i}/#{j}) abs=#{correct} f1=#{(100*(2*acc*prec)/(acc+prec)).round 2}"

