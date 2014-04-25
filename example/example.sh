#!/bin/bash

# memcached has to be running! `memcached -p 31337`

# run rebol with rampion variant for 1 epoch over 10 examples (data.*)
../rebol.rb \
  -k 100 \
  -i $(pwd)/data.in \
  -r $(pwd)/data.en \
  -g $(pwd)/data.gold \
  -h $(pwd)/data.funql \
  -w $(pwd)/../data/weights.init \
  -t $(pwd)/../data/stopwords.en \
  -c $(pwd)/cdec.ini \
  -b $(pwd)/cfg.rb \
  -o output-weights \
  -l \
  -e 0.01 \
  -j 1 \
  -v rampion 2>output.stderr > output.stdout

# translate test
/toolbox/cdec-dtrain/decoder/cdec \
  -c cdec.ini \
  -w output-weights 2>/dev/null \
  < data.in  \
  | ../scripts/geoquery/semparse.rb $(pwd)/cfg.rb \
  | ../scripts/geoquery/query.rb $(pwd)/cfg.rb > output-answers

# evaluate result
../scripts/geoquery/eval.rb \
  data.gold < output-answers > output-eval

