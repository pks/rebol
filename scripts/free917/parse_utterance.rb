#!/usr/bin/env ruby

require 'pty'
require 'expect'
def query(string)
 answer = "\n"
 @in.printf("#{string}\n")
 result = @out.expect(/^> /,timeout=30)
 if result!=nil
  result[0].delete!("\r\n")
  result[0].delete!("\n")
  result[0].delete!("\r")
  matchData = result[0].match(/Top value {    (.*)  }>/)
  if matchData!=nil
   save = matchData[1].gsub(/^ */,"")
   save = save.gsub(/ *$/,"")
   save = save.gsub(/ +/," ")
   answer = save+"\n"
  end
 end
 STDOUT.write answer
end

def main
 model = ARGV[0] #parser model to be used
 lines = Array.new
 answers = Array.new
 original_dir = Dir.pwd
 Dir.chdir ARGV[1] #location of sempre
 @out, @in, @pid = PTY.spawn("./sempre @mode=interact @domain=free917 @sparqlserver=localhost:3093 @cacheserver=local @load=#{model} @executeTopOnly=0")
 @out.expect(/^> /,timeout=300)[0]
 @in.printf("initialize model\n")
 result = @out.expect(/^> /,timeout=300)
 
 Dir.chdir original_dir
 while line = $stdin.gets
  query(line.chomp)
 end
end

main

