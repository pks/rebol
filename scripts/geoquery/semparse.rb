#!/usr/bin/env ruby

require 'nlp_ruby'


SMT_SEMPARSE = 'python /workspace/grounded/smt-semparse-cp/decode_sentence.py /workspace/grounded/smt-semparse-cp/working/full_dataset'

while line = STDIN.gets
  puts `#{SMT_SEMPARSE} "#{line}"`
end

