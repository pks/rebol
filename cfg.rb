#geoquery requirements:
# edit here to change the parser
SMT_SEMPARSE = 'python /path/to/decode_sentence.py/of/smt-semparse /path/to/smt-semparse/workdir'
# this should be a 'fixed' (one that doesn't abbreviate its output) version of eval.pl
EVAL_PL = '/path/to/wasp-1.0/data/geo-funql/eval/eval.pl'
# set to true to ignore zombie eval.pl procs
ACCEPT_ZOMBIES = true
#free917 requirements:
#location of sempre
SEMPRE = '/path/to/sempre'
#both
TIMEOUT = 60
# cdec binary
CDEC_BIN = '/path/to/cdec/decoder/cdec'
# memcached has to be running
$cache = Memcached.new('localhost:31337')

