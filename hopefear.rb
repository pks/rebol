def hope_and_fear kbest, action
  max = -1.0/0
  max_idx = -1
  kbest.each_with_index { |k,i|
    if action=='hope' && k.scores[:decoder] + k.scores[:psb] > max
      max_idx = i; max = k.scores[:decoder] + k.scores[:psb]
    end
    if action=='fear' && k.scores[:decoder] - k.scores[:psb] > max
      max_idx = i; max = k.scores[:decoder] - k.scores[:psb]
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
    hope = hope_and_fear kbest, 'hope'
    type2 = true
  end
  fear = hope_and_fear kbest, 'fear'
  return hope, fear, false, type1, type2
end

def gethopefear_fear_no_exec kbest, feedback, gold, max
  hope = fear = nil
  type1 = type2 = false
  if feedback == true
    hope = kbest[0]
    type1 = true
  else
    hope = hope_and_fear kbest, 'hope'
    type2 = true
  end
  # sorted in descending order by max(decoder, psb), best ('hope') first
  # select the 'best' translation that does not deliver the correct answer
  kbest.sort{ |x,y| (y.scores[:decoder]+y.scores[:psb])<=>(x.scores[:decoder]+x.scores[:psb]) }.each_with_index { |k,i|
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
    hope = hope_and_fear kbest, 'hope'
    type2 = true
  end
  fear = hope_and_fear(kbest, 'fear')
  # skip example if fear gives the right answer
  skip = exec(fear.s, gold, true)[0]
  return hope, fear, skip, type1, type2
end

def gethopefear_fear_no_exec_hope_exec kbest, feedback, gold, max
  hope = fear = nil; hope_idx = 0
  type1 = type2 = false
  # sorted in descending order by max(decoder, psb), best ('hope') first
  sorted_kbest = kbest.sort{ |x,y| (y.scores[:decoder]+y.scores[:psb])<=>(x.scores[:decoder]+x.scores[:psb]) }
  if feedback == true
    hope = kbest[0]
    type1 = true
  else
    # select 'best' translation that correctly executes
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
  # select 'best' translation that does not correctly execute
  sorted_kbest.each_with_index { |k,i|
    break if i>(kbest.size-(hope_idx+1))||i==max
    if !exec(k.s, gold, true)[0]
      fear = k
      break
    end
  }
  # skip if hope or fear could no be found
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
    hope = hope_and_fear kbest, 'hope'
    type2 = true
  end
  fear = hope_and_fear kbest, 'fear'
  # skip if fear executes correctly or hope doesn't
  skip = exec(fear.s, gold, true)[0]||!exec(hope.s, gold, true)[0]
  return hope, fear, skip, type1, type2
end

# new variant w/ "real" reference
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
    # search for first (by decoder score) translation that gives the correct answer
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
  # --"-- doesn't give the correct answer
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
  # 1best is automatically hope if it matches reference
  if kbest[0].s == reference
    hope = kbest[0]
    fear = hope_and_fear kbest, 'fear'
    type1 = true
  else
    hope = hope_and_fear kbest, 'hope'
    # 1best is automatically fear if it doesn't match reference
    fear = kbest[0]
    type2 = true
  end
  return hope, fear, false, type1, type2
end

