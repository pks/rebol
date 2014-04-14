import sys
import os
import tempfile, shutil
from src.extractor import Extractor
from src.smt_semparse_config import SMTSemparseConfig
from src.moses import Moses
from src.functionalizer import Functionalizer

#input: English sentence
if __name__ == '__main__':
  sentence = ''
  if len(sys.argv) == 3:
    experiment_dir = sys.argv[1]
    sentence = sys.argv[2]
  else:
    assert False
	
  # load config
  config = SMTSemparseConfig('/workspace/grounded/smt-semparse-cp/settings.yaml', '/workspace/grounded/smt-semparse-cp/dependencies.yaml')

  #stem
  sentence = Extractor(config).preprocess_nl(sentence)

  # we need a temp dir!
  temp_dir = tempfile.mkdtemp()

  #decode
  moses = Moses(config)
  moses.decode_sentence(experiment_dir, sentence, temp_dir)

  #convert to bracket structure
  print Functionalizer(config).run_sentence(experiment_dir, temp_dir)

  #delete tmp files
  shutil.rmtree(temp_dir)

