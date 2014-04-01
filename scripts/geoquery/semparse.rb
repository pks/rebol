#!/usr/bin/env ruby

require 'nlp_ruby'
require 'memcached'


require_relative ARGV[0]

while line = STDIN.gets
  puts `#{SMT_SEMPARSE} "#{line}"`
end

