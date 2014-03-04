#!/usr/bin/env ruby

require 'nlp_ruby'
require 'xmlsimple'


def extract fn='./corpus.xml', lang='en', ids
  doc = XmlSimple.xml_in(fn)
  doc['example'].each { |example|
    next if (!ids.include? example['id']) && ids.size>0
    if lang == 'funql' || lang == 'geo-prolog'
      puts example['mrl'][0]['content'].to_s.strip
    else
      example['nl'].each { |nl|
        if nl['lang'] == lang
          puts nl['content']
        else
          next
        end
      }
    end
  }
end

def main
  ids = []
  ids = ReadFile.readlines_strip ARGV[2]
  extract ARGV[0], ARGV[1], ids
end


main

