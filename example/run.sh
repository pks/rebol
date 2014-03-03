#!/bin/bash

# stop and start memcached
killall memcached
memcached &

# run lampion with rampion variant for 3 epochs over 30 examples
../lampion.rb \
  -k 100 \
  -i train.in \
  -r train.en \
  -g train.gold \
  -h train.funql \
  -w weights.init \
  -c cdec.ini \
  -t stopwords.en \
  -o output-weights \
  -l \
  -e 0.01 \
  -j 3 \
  -s 30 \
  -v rampion 2> output.stderr > output.stdout

# translate test
/toolbox/cdec-dtrain/decoder/cdec \
  -c cdec.ini \
  -w output-weights.2.gz 2>/dev/null \
  < test.in  \
  | ../scripts/geoquery/semparse.rb \
  | ../scripts/geoquery/query.rb > output-answers

# evaluate result
../scripts/geoquery/eval.rb \
  test.gold < output-answers > output-eval

