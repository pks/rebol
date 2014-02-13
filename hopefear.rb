def hope_and_fear kbest, action
  max = -1.0/0
  max_idx = -1
  kbest.each_with_index { |i,j|
    if action=='hope' && i.score + i.other_score > max
      max_idx = j; max = i.score + i.other_score
    end
    if action=='fear' && i.score - i.other_score > max
      max_idx = j; max = i.score - i.other_score
    end
  }
  return kbest[max_idx]
end

def gethopefear_standard kbest, feedback
  hope = fear = nil
  type1 = type2 = false
  if feedback == true
    hope = kbest[0]
    type1 = true
  else
    hope = hope_and_fear(kbest, 'hope')
    type2 = true
  end
  fear = hope_and_fear(kbest, 'fear')
  return hope, fear, false, type1, type2
end

def gethopefear_fear_no_exec kbest, feedback, gold, max
  hope = fear = nil
  type1 = type2 = false
  if feedback == true
    hope = kbest[0]
    type1 = true
  else
    hope = hope_and_fear(kbest, 'hope')
    type2 = true
  end
  kbest.sort{|x,y|(y.score+y.other_score)<=>(x.score+x.other_score)}.each_with_index { |k,i|
    break if i==max
    if !exec(k.s, gold, true)[0]
       fear = k
       break
    end
  }
  skip=true if !fear
  return hope, fear, skip, type1, type2
end

def gethopefear_fear_no_exec_skip kbest, feedback, gold
  hope = fear = nil
  type1 = type2 = false
  if feedback == true
    hope = kbest[0]
    type1 = true
  else
    hope = hope_and_fear(kbest, 'hope')
    type2 = true
  end
  fear = hope_and_fear(kbest, 'fear')
  skip = exec(fear.s, gold, true)[0]
  return hope, fear, skip, type1, type2
end

def gethopefear_fear_no_exec_hope_exec kbest, feedback, gold, max
  hope = fear = nil; hope_idx = 0
  type1 = type2 = false
  sorted_kbest = kbest.sort{|x,y|(y.score+y.other_score)<=>(x.score+x.other_score)}
  if feedback == true
    hope = kbest[0]
    type1 = true
  else
    sorted_kbest.each_with_index { |k,i|
      next if i==0
      break if i==max
      if exec(k.s, gold, true)[0]
        hope_idx = i
        hope = k
        break
      end
    }
    type2 = true
  end
  sorted_kbest.each_with_index { |k,i|
    break if i>(kbest.size-(hope_idx+1))||i==max
    if !exec(k.s, gold, true)[0]
      fear = k
      break
    end
  }
  skip = true if !hope||!fear
  return hope, fear, skip, type1, type2
end

def gethopefear_fear_no_exec_hope_exec_skip kbest, feedback, gold, max
  hope = fear = nil
  type1 = type2 = false
  if feedback == true
    hope = kbest[0]
    type1 = true
  else
    hope = hope_and_fear(kbest, 'hope')
    type2 = true
  end
  fear = hope_and_fear(kbest, 'fear')
  skip = exec(fear.s, gold, true)[0]||!exec(hope.s, gold, true)[0]
  return hope, fear, skip, type1, type2
end


def gethopefear_only_exec kbest, feedback, gold, max, own_reference=nil
  hope = fear = nil; hope_idx = 0; new_reference = nil
  type1 = type2 = false
  if feedback == true
    hope = kbest[0]
    new_reference = hope
    type1 = true
  elsif own_reference
    hope = own_reference
    type1 = true
  else
    kbest.each_with_index { |k,i|
      next if i==0
      break if i==max
      if exec(k.s, gold, true)[0]
        hope_idx = i
        hope = k
        break
      end
    }
    type2 = true
  end
  kbest.each_with_index { |k,i|
    next if i==0||i==hope_idx
    break if i==max
    if !exec(k.s, gold, true)[0]
      fear = k
      break
    end
  }
  skip = true if !hope||!fear
  return hope, fear, skip, type1, type2, new_reference
end

def gethopefear_only_exec_simple kbest, feedback, gold, max, own_reference=nil
  hope = fear = nil; hope_idx = 0; new_reference = nil
  type1 = type2 = false
  if feedback == true
    hope = kbest[0]
    new_reference = hope
    type1 = true
  elsif own_reference
    hope = own_reference
    type1 = true
  else
    kbest.each_with_index { |k,i|
      next if i==0
      break if i==max
      if exec(k.s, gold, true)[0]
        hope_idx = i
        hope = k
        break
      end
    }
    type2 = true
  end
  kbest.each_with_index { |k,i|
    next if i==0||i==hope_idx
    break if i==max
    if !exec(k.s, gold, true)[0]
      fear = k
      break
    end
  }
  skip = true if !hope||!fear
  return hope, fear, skip, type1, type2, new_reference
end

def gethopefear_rampion kbest, reference
  hope = fear = nil
  type1 = type2 = false
  if kbest[0].s == reference
    hope = kbest[0]
    fear = hope_and_fear(kbest, 'fear')
    type1 = true
  else
    hope = hope_and_fear(kbest, 'hope')
    fear = kbest[0]
    type2 = true
  end
  return hope, fear, false, type1, type2
end

