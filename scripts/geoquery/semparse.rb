#!/usr/bin/env ruby

require 'nlp_ruby'
require_relative '../../cfg.rb'


while line = STDIN.gets
  puts `#{SMT_SEMPARSE} "#{line}"`
end

