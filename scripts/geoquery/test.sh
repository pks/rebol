#!/bin/sh

/workspace/grounded/lampion/scripts/geoquery/translate.sh $1 $2 < /workspace/grounded/lampion/proper/d/split880.test.in | tee $2.transl | /workspace/grounded/lampion/scripts/geoquery/semparse.rb $3 | tee $2.parsed | /workspace/grounded/lampion/scripts/geoquery/query.rb $3 > $2.output
/workspace/grounded/lampion/scripts/geoquery/eval.rb /workspace/grounded/lampion/proper/d/split880.test.gold < $2.output > $2.result

