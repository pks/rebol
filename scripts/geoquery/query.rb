#!/usr/bin/env ruby

require 'nlp_ruby'
require_relative '../../cfg.rb'


while line = STDIN.gets
  puts `echo "execute_funql_query(#{line}, X)." | swipl -s #{EVAL_PL} 2>&1  | grep "X ="`.gsub('X = ','').strip
end

