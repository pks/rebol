#!/usr/bin/env ruby

require 'trollop'
require 'tempfile'
require 'open3'


SMT_SEMPARSE = 'python /workspace/grounded/smt-semparse-cp/decode_sentence.py /workspace/grounded/smt-semparse-cp/working/full_dataset'
EVAL_PL = '/workspace/grounded/wasp-1.0/data/geo-funql/eval/eval.pl'
CDEC = "/toolbox/cdec-dtrain/bin/cdec"

# execute
def exec natural_language_string, reference_output, no_output=false
  func   = `#{SMT_SEMPARSE} "#{natural_language_string}"`.strip
  output = `echo "execute_funql_query(#{func}, X)." | swipl -s #{EVAL_PL} 2>&1  | grep "X ="`.strip.split('X = ')[1]
  puts "        nrl: #{natural_language_string}" if !no_output
  puts "        mrl: #{func}" if !no_output
  puts "     output: #{output}" if !no_output
  puts "   correct?: #{output==reference_output}" if !no_output
  return output==reference_output, func, output
end

# decoder interaction/translations
class Translation
  attr_accessor :s, :f, :rank, :model, :score

  def initialize kbest_line, rank=-1
    a = kbest_line.split ' ||| '
    @s = a[1].strip
    h = {}
    a[2].split.each { |i|
      name, value = i.split '='
      value = value.to_f
      h[name] = value
    }
    @f = NamedSparseVector.new h
    @rank = rank
    @model = a[3].to_f
    @score = -1.0
  end

  def to_s
    "#{@rank} ||| #{@s} ||| #{@model} ||| #{@score} ||| #{@f.to_s}"
  end
end

def predict_translation s, k, ini, w
  o, s = Open3.capture2 "echo \"#{s}\" | #{CDEC} -c #{ini} -r -k #{k} -w #{w} 2>/dev/null"
  j = -1
  return o.split("\n").map{|i| j+=1; Translation.new(i, j)}
end

# scoring (per-sentence BLEU)
def ngrams_it(s, n, fix=false)
  a = s.strip.split
  a.each_with_index { |tok, i|
    tok.strip!
    0.upto([n-1, a.size-i-1].min) { |m|
      yield a[i..i+m] if !(fix||(a[i..i+m].size>n))
    }
  }
end

def brevity_penalty hypothesis, reference
  a = hypothesis.split; b = reference.split
  return 1.0 if a.size>b.size
  return Math.exp(1.0 - b.size.to_f/a.size);
end

def per_sentence_bleu hypothesis, reference, n=4
  h_ng = {}; r_ng = {}
  (1).upto(n) {|i| h_ng[i] = []; r_ng[i] = []}
  ngrams_it(hypothesis, n) {|i| h_ng[i.size] << i}
  ngrams_it(reference, n) {|i| r_ng[i.size] << i}
  m = [n, reference.split.size].min
  weight = 1.0/m
  add = 0.0
  sum = 0
  (1).upto(m) { |i|
    counts_clipped = 0
    counts_sum = h_ng[i].size
    h_ng[i].uniq.each {|j| counts_clipped += r_ng[i].count(j)}
    add = 1.0 if i >= 2
    sum += weight * Math.log((counts_clipped + add)/(counts_sum + add));
  }
  return brevity_penalty(hypothesis, reference) * Math.exp(sum)
end

def score_translations list_of_translations, reference
  list_of_translations.each { |i| i.score = per_sentence_bleu i.s, reference}
end

# hope and fear
def hope_and_fear kbest, action
  max = -1.0/0
  max_idx = -1
  kbest.each_with_index { |i,j|
  if action=='hope' && i.model + i.score > max
    max_idx = j; max = i.model + i.score
  end
  if action=='fear' && i.model - i.score > max
    max_idx = j; max = i.model - i.score
  end
  }
  return kbest[max_idx]
end

# update
def update w, hope, fear, eta
  diff = hope.f - fear.f
  diff *= eta
  w += diff
  return w
end

# weights
class NamedSparseVector
  attr_accessor :h

  def initialize init=nil
    @h = {}
    @h = init if init
    @h.default = 0.0
  end

  def + other
    new_h = Hash.new
    new_h.update @h
    ret = NamedSparseVector.new new_h
    other.each_pair { |k,v| ret[k]+=v }
    return ret
  end

  def from_file fn
    f = File.new(fn, 'r')
    while line = f.gets
      name, value = line.strip.split
      value = value.to_f
      @h[name] = value
    end
  end

  def to_file
    s = []
    @h.each_pair { |k,v| s << "#{k} #{v}" }
    s.join("\n")+"\n"
  end

  def - other
    new_h = Hash.new
    new_h.update @h
    ret = NamedSparseVector.new new_h
    other.each_pair { |k,v| ret[k]-=v }
    return ret
  end

  def * scalar
    raise ArgumentError, "Arg is not numeric #{scalar}" unless scalar.is_a? Numeric
    ret = NamedSparseVector.new
    @h.keys.each { |k| ret[k] = @h[k]*scalar }
    return ret
  end

  def dot other
    sum = 0.0
    @h.each_pair { |k,v|
      sum += v * other[k]
    }
    return sum
  end

  def [] k
    @h[k]
  end

  def []= k, v
    @h[k] = v
  end

  def each_pair
    @h.each_pair { |k,v| yield k,v }
  end

  def to_s
    @h.to_s
  end

  def length
    Math.sqrt(@h.values.map{|i|i*i}.inject(:+))
  end

  def normalize!
    l = length
    @h.each_pair { |k,v|
      @h[k] = v/l
    }
  end

  def size
    @h.keys.size
  end
end

# map models score to [0,1]
def adj_model kbest, factor
  min = kbest.map{|i|i.model}.min
  max = kbest.map{|i|i.model}.max
  kbest.each {|i| i.model = factor*((i.model-min)/(max-min))}
end

class Stats
  def initialize name
    @name = name
    @with_parse = 0.0
    @with_output       = 0.0
    @correct_output    = 0.0
  end

  def update feedback, func, output
    @with_parse +=1 if func!="None"
    @with_output +=1 if output!="null"
    @correct_output += 1 if feedback==true
  end

  def print total
<<-eos
  [#{@name}]
         with parse #{((@with_parse/total)*100).round 2} abs:#{@with_parse}
        with output #{((@with_output/total)*100).round 2} abs:#{@with_output}
with correct output #{((@correct_output/total)*100).round 2} abs:#{@correct_output}
eos
  end
end

def _print rank, string, model, score
    puts "rank=#{rank} string='#{string}' model=#{model} score=#{score}"
end

def bag_of_words s, stopwords=[]
  s.split.uniq.sort.reject{|v| stopwords.include? v}
end

def main
  opts = Trollop::options do
    opt :k, "k", :type => :int, :required => true
    opt :input, "'foreign' input", :type => :string, :required => true
    opt :references, "(parseable) references", :type => :string, :required => true
    opt :gold, "gold output", :type => :string, :require => true
    opt :gold_mrl, "gold parse", :type => :string, :short => '-h', :require => true
    opt :init_weights, "initial weights", :type => :string, :required => true, :short => '-w'
    opt :cdec_ini, "cdec config file", :type => :string, :default => './cdec.ini'
    opt :eta, "learning rate", :type => :float, :default => 0.01
    opt :no_update, "don't update weights", :type => :bool, :default => false
    opt :stop_after, "stop after x examples", :type => :int, :default => -1
    opt :output_weights, "output file for final weights", :type => :string, :required => true
    opt :scale_model, "scale model score by this factor", :type => :float, :default => 1.0, :short => '-m'
    opt :normalize, "normalize weights after each update", :type => :bool, :default => false, :short => '-l'
    opt :print_kbests, "print full kbest lists", :type => :bool, :default => false, :short => '-j'
    opt :hope2, "select hope from the first X items in kbest that executes", :type => :int, :default => 0, :short => '-x'
    opt :fear2, "skip example if fear executes", :type => :bool, :default => false
  end

  puts "cfg"
  opts.each_pair {|k,v| puts "#{k}\t#{v}"}
  puts

  input      = File.new(opts[:input], 'r').readlines.map{|i|i.strip}
  references = File.new(opts[:references], 'r').readlines.map{|i|i.strip}
  gold       = File.new(opts[:gold], 'r').readlines.map{|i|i.strip}
  gold_mrl   = File.new(opts[:gold_mrl], 'r').readlines.map{|i|i.strip}

  stopwords = File.new('stopwords.en', 'r').readlines.map{|i|i.strip}

  # init weights
  w = NamedSparseVector.new
  w.from_file opts[:init_weights]

  without_translations = 0
  count                = 0
  top1_stats = Stats.new 'top1'
  hope_stats = Stats.new 'hope'
  fear_stats = Stats.new 'fear'
  refs_stats = Stats.new 'refs'
  type1_updates = 0
  type2_updates = 0
  top1_hit = 0
  top1_variant = 0
  top1_real_variant = 0
  hope_hit = 0
  hope_variant = 0
  hope_real_variant = 0
  kbest_sz = 0
  last_wf = ''
  input.each_with_index { |i,j|
    count += 1
    # write current weights to file
    tmp_file = Tempfile.new('rampion')
    tmp_file_path = tmp_file.path
    last_wf = tmp_file.path
    tmp_file.write w.to_file
    tmp_file.close
    # get kbest list for current input
    kbest = predict_translation i, opts[:k], opts[:cdec_ini], tmp_file_path
    kbest_sz += kbest.size
    if kbest.size==0
      without_translations += 1
      next
    end
    score_translations kbest, references[j]
    if opts[:print_kbests]
      puts "KBEST"
      kbest.each_with_index { |k,l|
        _print l, k.s, k.model, k.score
      }
    end
    adj_model kbest, opts[:scale_model]
    # get feedback
    puts "EXAMPLE #{j}"
    puts "GOLD MRL: #{gold_mrl[j]}"
    puts "GOLD OUTPUT #{gold[j]}"
    # fear
    fear = hope_and_fear kbest, 'fear'
    if opts[:fear2]
      f, g, o = exec fear.s, gold[j], true
      if f
        puts "FEAR EXECUTED, skipping example\n\n"
        next
      end
    end
    # top1
    puts "---top1"
    _print 0, kbest[0].s, kbest[0].model, kbest[0].score
    feedback, func, output = exec kbest[0].s, gold[j]
    # hope2
    parses = []
    if opts[:hope2]>0
      already_seen = {}
      puts "<<KBEST EXEC"
      (1).upto([opts[:hope2]-1, kbest.size-1].min) { |l|
        f, g, o = exec kbest[l].s, gold[j], true
        words = bag_of_words kbest[l].s, stopwords
        parses << f
        puts "#{f} | #{l} | #{kbest[l].s} #{words.to_s}" if !already_seen.has_key? words
        already_seen[words] = true
      }
      puts ">>>"
    end
    top1_stats.update feedback, func, output
    # hope & update
    ref_words = bag_of_words references[j], stopwords
    hope = nil
    if feedback==true
      if kbest[0].s == references[j]
        top1_hit +=1
      else
        top1_variant += 1
        top1_real_variant += 1 if bag_of_words(kbest[0].s,stopwords)!=ref_words
      end
      #references[j] = kbest[0].s
      hope = kbest[0]
      type1_updates += 1
    else
      if opts[:hope2]>0
        c=-1; found = parses.detect{|b| c+=1; b }
        hope = kbest[c] if found
        if !found
          puts "NO GOOD HOPE, skipping example\n\n"
          next
        end
      else
        hope = hope_and_fear kbest, 'hope'
      end
      if hope.s == references[j]
        hope_hit += 1
      else
        hope_variant += 1
        hope_real_variant += 1 if bag_of_words(hope.s,stopwords)!=ref_words
      end
      type2_updates += 1
    end

    puts "---hope"
    _print hope.rank, hope.s, hope.model, hope.score
    feedback, func, output =  exec hope.s, gold[j]
    hope_stats.update feedback, func, output
    puts "---fear"
    _print fear.rank, fear.s, fear.model, fear.score
    feedback, func, output = exec fear.s, gold[j]
    fear_stats.update  feedback, func, output
    puts "---reference"
    _print 'x', references[j], 'x', 1.0
    feedback, func, output = exec references[j], gold[j]
    refs_stats.update feedback, func, output

    puts

    w = update w, hope, fear, opts[:eta] if !opts[:no_update]
    w.normalize! if opts[:normalize]
    break if opts[:stop_after]>0 && (j+1)==opts[:stop_after]
  }
  FileUtils::cp(last_wf, opts[:output_weights])
  puts "#{count} examples"
  puts "    type1 updates: #{type1_updates}"
  puts "    type2 updates: #{type2_updates}"
  puts "        top1 hits: #{top1_hit}"
  puts "     top1 variant: #{top1_variant}"
  puts "top1 real variant: #{top1_real_variant}"
  puts "        hope hits: #{hope_hit}"
  puts "     hope variant: #{hope_variant}"
  puts "hope real variant: #{hope_real_variant}"
  puts "       kbest size: #{(kbest_sz/count).round 2}"
  puts "#{((without_translations.to_f/count)*100).round 2}% without translations (abs: #{without_translations})"
  puts top1_stats.print count
  puts hope_stats.print count
  puts fear_stats.print count
  puts refs_stats.print count
end


main

