_PATH          = '/workspace/grounded/test'
SMT_SEMPARSE   = "python #{_PATH}/smt-semparse/decode_sentence.py /workspace/grounded/test/smt-semparse/work/full_dataset"
EVAL_PL        = "#{_PATH}/wasp-1.0/data/geo-funql/eval/eval.pl"
ACCEPT_ZOMBIES = true
TIMEOUT        = 60
CDEC_BIN       = '/toolbox/cdec/decoder/cdec'
$cache         = Memcached.new('localhost:31337')

