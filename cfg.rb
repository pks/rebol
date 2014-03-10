# edit here to change the parser
SMT_SEMPARSE = 'python /workspace/grounded/smt-semparse-cp/decode_sentence.py /workspace/grounded/smt-semparse-cp/working/full_dataset'
# this is the 'fixed' version of eval.pl
EVAL_PL = '/workspace/grounded/wasp-1.0/data/geo-funql/eval/eval.pl'
# set to true to ignore zombie eval.pl procs
ACCEPT_ZOMBIES = true
TIMEOUT=60
# cdec binary
CDEC_BIN = '/toolbox/cdec-dtrain/decoder/cdec'
# memcached has to be running
$cache = Memcached.new('localhost:11211')

