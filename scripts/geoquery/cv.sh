#!/bin/bash

function wait_for()
{
  echo "Waiting for ${#WAITFOR[@]} procs..."
  echo ${WAITFOR[*]}
  for pid in ${WAITFOR[@]}; do
      wait $pid;
  done
}

killall memcached
memcached &

K=100
J=10
STOPWORDS=/path/to/stopwords.en

for VARIANT in rebol rampion exec; do
for E in 0.3 0.1 0.01 0.03 0.003 0.001 0.0003 0.0001; do
for INI in /paths/to/cdec/inis; do
for INIT_WEIGHTS in /paths/to/weight/files; do
WAITFOR=()
for FOLD in {0..9}; do

NAME="v=$VARIANT.fold=$FOLD.e=$E.c=$(basename $INI).w=$(basename $INIT_WEIGHTS)"

../rampfion.rb \
  -k $K \
  -i /path/to/folds600/$FOLD/train.in \
  -r /path/tod/folds600/$FOLD/train.en \
  -g /path/to/folds600/$FOLD/train.gold \
  -h /path/to/folds600/$FOLD/train.funql \
  -w $INIT_WEIGHTS \
  -t $STOPWORDS \
  -c $INI \
  -b $(pwd)/cfg.rb \
  -e $E \
  -j $J \
  -v $VARIANT \
  -o $NAME.weights &> $NAME.output &
WAITFOR+=( $! )

done
wait_for $WAITFOR
done
done
done
done

