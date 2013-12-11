#!/usr/bin/env ruby20

require 'trollop'
require 'open3'


# execute TODO
SMT_SEMPARSE = ''
EVAL_PL = ''
def exec natural_language_string, reference_output
  return false
  # parse...
  #r = `echo "execute_funql_query(#{natural_language_string}, X)." | swipl -s #{EVAL_PL} 2>&1  | grep "X ="`
  #return r==reference_output
end


# decoder interaction/translations
class Translation
  attr_accessor :s, :f, :rank, :model, :score

  def initialize kbest_line, rank=-1
    a = kbest_line.split ' ||| '
    @s = a[1].strip
    h = {}
    a[2].split.each { |i|
      name, value = i.split
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

CDEC = "~/src/cdec-dtrain/decoder/cdec -r"
def predict_translation s, k, ini, w
  cmd = " echo \"#{s}\" | #{CDEC} -c #{ini} -k #{k} -w #{w} 2>/dev/null"
  o, s = Open3.capture2(cmd)
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

def brevity_penalty h, r
  a = h.split
  b = r.split
  return 1.0 if a.size>b.size
  return Math.exp(1.0 - b.size.to_f/a.size);
end

def per_sentence_bleu h, r, n=4
  h_ng = {}
  r_ng = {}
  (1).upto(n) { |i| h_ng[i] = []; r_ng[i] = [] }
  ngrams_it(h, n) { |i| h_ng[i.size] << i }
  ngrams_it(r, n) { |i| r_ng[i.size] << i }
  m = [n,r.split.size].min
  weight = 1.0/m
  add = 0.0
  sum = 0
  (1).upto(m) { |i|
    counts_clipped = 0
    counts_sum = h_ng[i].size
    h_ng[i].uniq.each { |j| counts_clipped += r_ng[i].count(j) }
    add = 1.0 if i >= 2
    sum += weight * Math.log((counts_clipped + add)/(counts_sum + add));
  }
  return brevity_penalty(h,r) * Math.exp(sum)
end

def score_translations a, reference
  a.each_with_index { |i,j|
    i.score = per_sentence_bleu i.s, reference
  }
end
### /scoring



### hope and fear
def hope_and_fear a, act='hope'
  max = -1.0/0
  max_idx = -1
  a.each_with_index { |i,j|
  if act=='hope' && i.model + i.score > max
    max_idx = j; max = i.model + i.score
  end
  if act=='fear' && i.model - i.score > max
    max_idx = j; max = i.model - i.score
  end
  }
  return a[max_idx]
end
### /hope and fear



### update
def update w, hope, fear
  w = w + (hope.f - fear.f)
  return w
end
### /update



### weights
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
    s.join "\n"
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

  def size
    @h.keys.size
  end
end
### /weights


def test opts
  w = NamedSparseVector.new
  w.from_file opts[:init_weights]
  input = File.new(opts[:input], 'r').readlines.map{|i|i.strip}
  references = File.new(opts[:references], 'r').readlines.map{|i|i.strip}
  f = File.new('weights.tmp', 'w+')
  f.write w.to_file
  f.close
  kbest = predict_translation input[0], opts[:k], 'weights.tmp'
  score_translations kbest, references[0]
  kbest.each_with_index { |i,j|
    puts "#{i.rank} #{i.s} #{i.model} #{i.score}"
  }
  puts
  puts "hope"
  hope = hope_and_fear kbest, 'hope'
  puts "#{hope.rank} #{hope.s} #{hope.model} #{hope.score}"
  puts "fear"
  fear = hope_and_fear kbest, 'fear'
  puts "#{fear.rank} #{fear.s} #{fear.model} #{fear.score}"
end

def adj_model a
  x = 0.0
  a.each {|i| x += i.model }
  a.each {|i| i.model = i.model/x }
end

def main
  opts = Trollop::options do
    opt :k, "k", :type => :int, :required => true
    opt :input, "'foreign' input", :type => :string, :required => true
    opt :references, "(parseable) references", :type => :string, :required => true
    opt :init_weights, "initial weights", :type => :string, :required => true, :short => '-w'
    opt :cdec_ini, "cdec config file", :type => :string, :default => './cdec.ini'
  end

  input = File.new(opts[:input], 'r').readlines.map{|i|i.strip}
  references = File.new(opts[:references], 'r').readlines.map{|i|i.strip}

  # init weights
  w = NamedSparseVector.new
  w.from_file opts[:init_weights]

  input.each_with_index { |i,j|
    # write current weights to file
    f = File.new('weights.tmp', 'w+')
    f.write w.to_file
    f.close
    # get kbest list for current input
    kbest = predict_translation i, opts[:k], opts[:cdec_ini], 'weights.tmp'
    score_translations kbest, references[j]
    adj_model kbest
    # get feedback
    feedback = exec kbest[0].s, nil #TODO
    hope = ''; fear = ''
    if feedback == true
      references[i] = kbest[0].s
      hope = kbest[0].s
    else
      hope = hope_and_fear kbest, 'hope'
    end
    fear = hope_and_fear kbest, 'fear'

    puts "hope: #{hope.rank} #{hope.s} #{hope.model} #{hope.score}"
    puts "fear: #{fear.rank} #{fear.s} #{fear.model} #{fear.score}"
    puts
    w = update w, hope, fear
  }
end


main

