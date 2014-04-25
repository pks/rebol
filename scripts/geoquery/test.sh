#!/bin/sh

/workspace/grounded/rebol/scripts/geoquery/translate.sh $1 $2 < /workspace/grounded/rebol/proper/d/split880.test.in | tee $2.transl | /workspace/grounded/rebol/scripts/geoquery/semparse.rb $3 | tee $2.parsed | /workspace/grounded/rebol/scripts/geoquery/query.rb $3 > $2.output
/workspace/grounded/rebol/scripts/geoquery/eval.rb /workspace/grounded/rebol/proper/d/split880.test.gold < $2.output > $2.result

