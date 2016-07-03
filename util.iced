exports.ktuples = ktuples = (set, k) ->
  if k is 1 then return ([x] for x in set)
  ret = []
  for x, i in set
    for tuple in ktuples(set.slice(i + 1), k - 1)
      ret.push [x].concat(tuple)
  return ret

