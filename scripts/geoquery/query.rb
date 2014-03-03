#!/usr/bin/env ruby

require 'nlp_ruby'


EVAL_PL='/workspace/grounded/wasp-1.0/data/geo-funql/eval/eval.pl'

while line = STDIN.gets
  puts `echo "execute_funql_query(#{line}, X)." | swipl -s #{EVAL_PL} 2>&1  | grep "X ="`.gsub('X = ','').strip
end

