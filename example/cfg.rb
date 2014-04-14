SMT_SEMPARSE   = 'python /workspace/grounded/smt-semparse-cp/decode_sentence.py /workspace/grounded/smt-semparse-cp/working/full_dataset'
EVAL_PL        = '/workspace/grounded/wasp-1.0/data/geo-funql/eval/eval.pl'
ACCEPT_ZOMBIES = true
TIMEOUT        = 60
CDEC_BIN       = '/toolbox/cdec-dtrain/decoder/cdec'
$cache         = Memcached.new('localhost:31337')

