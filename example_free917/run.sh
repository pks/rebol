#!/bin/bash

# memcached has to be running!
#memcached -p 31337

#NOTE: when you change sempre models make sure you delete the file LexiconFn.cache located in your sempre installation folder!
CDEC=/path/to/cdec
SEMPRE=/path/to/sempre
MODEL=1

../rebol.rb \
  -k 100 \
  -i $(pwd)/data.in \
  -r $(pwd)/data.en \
  -g $(pwd)/data.gold \
  -h $(pwd)/data.mrl \
  -w $(pwd)/../data/weights.init \
  -t $(pwd)/../data/stopwords.en \
  -c $(pwd)/cdec.ini \
  -b $(pwd)/cfg.rb \
  -o output-weights \
  -l \
  -e 0.01 \
  -j 1 \
  -u free917 \
  -z $MODEL \
  -v rebol 2>output.stderr > output.stdout


# translate test
$CDEC/decoder/cdec \
  -c cdec.ini \
  -w output-weights 2>/dev/null \
  < data.in >output-translation
  
#get answers
../scripts/free917/parse_utterance.rb $MODEL $SEMPRE <output-translation >output-answers

# evaluate result
../scripts/free917/eval.rb \
  data.gold < output-answers > output-eval