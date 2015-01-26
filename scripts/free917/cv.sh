#!/bin/bash

killall memcached
memcached &

K=100
J=10
SEMPRE=/path/to/sempre
STOPWORDS=/path/to/stopwords.en
CFG=/home/mitarb/haas1/caro/rebol/cfg.rb
MODEL=1

for VARIANT in rebol rampion exec; do
for INI in /paths/to/cdec/inis; do
for INIT_WEIGHTS in /paths/to/weight/files; do
for E in 0.0001 0.0003 0.001 0.003 0.01 0.03 0.1 0.3; do

NAME="v=$VARIANT.e=$E.c=$(basename $INI).w=$(basename $INIT_WEIGHTS).m=$MODEL/"

cd $cwd
mkdir $NAME

for COUNT in #number of folds
do	
	cd $cwd
	cd $NAME
	mkdir $COUNT
	cd $COUNT
	for DEV in #number of folds
	do
		if [ $COUNT != $DEV ]
		then
			cat /path/to/free917v2.$DEV.in >> free917v2.dev.in
			cat /path/to/free917v2.$DEV.tok.en >> free917v2.dev.tok.en
			cat /path/to/free917v2.$DEV.gold >> free917v2.dev.gold
			cat /path/to/free917v2.$DEV.mrl >> free917v2.dev.mrl
		fi
	done
	../rebol.rb \
	  -k $K \
	  -i /path/tofree917v2.dev.in \
	  -r /path/tofree917v2.dev.tok.en \
	  -g /path/tofree917v2.dev.gold \
	  -h /path/tofree917v2.dev.mrl \
	  -w $INIT_WEIGHTS \
	  -c $INI \
	  -t $STOPWORDS \
	  -o $NAME.weights \
	  -b $CFG \
	  -l \
	  -e $E \
	  -j $J \
	  -u free917 \
	  -z $MODEL \
	  -v $VARIANT &> $NAME.output &

done
done
done
done
done
