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
  return max_idx
end

def gethopefear_rebol kbest, feedback, gold, max, own_reference=nil
  hope = fear = nil; new_reference = nil
  type1 = type2 = false
  if feedback == true
    # hope
    hope = kbest[0]
    new_reference = hope
    kbest.each { |k| k.scores[:psb] = BLEU::per_sentence_bleu k.s, new_reference }
    # fear
    kbest.sort_by { |k| -(k.scores[:model]-k.score[:psb]) }.each_with_index { |k,i|
      break if i==max
      if !exec(k.s, gold, true)[0]
        fear = k
        break
      end
    }
    type1 = true
  else
    # fear
    fear = kbest[0]
    # hope
    kbest.sort_by { |k| -(k.scores[:model]+k.score[:psb]) }.each_with_index { |k,i|
      break if i==max
      if exec(k.s, gold, true)[0]
        hope = k
        break
      end
    }
    type2 = true
  end
  skip = true if !hope||!fear
  return hope, fear, skip, type1, type2, new_reference
end

def gethopefear_rebol_light kbest, feedback, gold
  hope = fear = nil
  type1 = type2 = false
  if feedback == true
    hope = kbest[0]
    type1 = true
  else
    hope = kbest[hope_and_fear kbest, 'hope']
    type2 = true
  end
  fear = kbest[hope_and_fear kbest, 'fear']
  # skip example if fear gives the right answer
  skip = exec(fear.s, gold, true)[0]
  return hope, fear, skip, type1, type2
end

def gethopefear_exec kbest, feedback, gold, max, own_reference=nil
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
    fear = kbest[hope_and_fear kbest, 'fear']
    type1 = true
  else
    hope = kbest[hope_and_fear kbest, 'hope']
    # 1best is automatically fear if it doesn't match reference
    fear = kbest[0]
    type2 = true
  end
  return hope, fear, false, type1, type2
end

