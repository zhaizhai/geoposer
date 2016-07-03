assert = require 'assert'
{
  Diagram, Pt, Proj, Midpt, Intersect
} = require 'diagram.iced'
{ktuples} = require 'util.iced'
G = require 'geometry.js'

class MidpointGen
  @is_candidate = (d, a, b) ->
    # TODO: maybe canonicalize here

    # Diagram d
    for k, v of d._items # TODO
      if v.type isnt 'Midpt'
        continue

      if a is v.deps[0] and b is v.deps[1]
        # duplicate
        return false

      # avoid iterated midpoint constructions
      l = d.get(a + '.' + b)
      for s in [a, b]
        t = d.get(s)
        if t.type is 'Midpt' and d.get(t.deps[0] + '.' + t.deps[1]) is l
          return false

    return true

  @list_candidates = (d) ->
    ret = []
    pts = d.list_points()
    for i in [0...pts.length]
      for j in [0...i]
        [a, b] = [pts[i], pts[j]].sort()
        if @is_candidate d, a, b
          ret.push [a, b]
    return ret

  @define = (i, d, pairs, a, b) ->
    if pairs[a] is b or (pairs[a] is a and pairs[b] is b)
      d.define ->
        Midpt "A#{i}", a, b
      pairs["A#{i}"] = "A#{i}"
    else
      d.define =>
        Midpt "B#{i}", a, b
        Midpt "C#{i}", pairs[a], pairs[b]
      pairs["B#{i}"] = "C#{i}"
      pairs["C#{i}"] = "B#{i}"

exports.MidpointGen = MidpointGen