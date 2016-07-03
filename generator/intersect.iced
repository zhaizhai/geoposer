assert = require 'assert'
{
  Diagram, Pt, Proj, Midpt, Intersect
} = require 'diagram.iced'
{ktuples} = require 'util.iced'
G = require 'geometry.js'


class IntersectGen
  @is_candidate = (d, l1, l2) ->
    line1 = d.ensure_line(l1)
    line2 = d.ensure_line(l2)

    for pt in d.list_points()
      # intersection exists
      if (pt in line1.contains.concat(line1.deps) and
          pt in line2.contains.concat(line2.deps))
        return false

    for k, v of d._items # TODO
      if v.type isnt 'Intersect'
        continue
      if (line1 is d.get(v.deps[0]) and
          line2 is d.get(v.deps[1]))
        return false
    return true

  @list_candidates = (d) ->
    ret = []
    pts = d.list_points()
    for [w, x, y, z] in ktuples(pts, 4)
      l1 = [w, x].sort().join('.')
      l2 = [y, z].sort().join('.')
      if @is_candidate d, l1, l2
        ret.push [l1, l2]
      l1 = [w, y].sort().join('.')
      l2 = [x, z].sort().join('.')
      if @is_candidate d, l1, l2
        ret.push [l1, l2]
      l1 = [w, z].sort().join('.')
      l2 = [x, y].sort().join('.')
      if @is_candidate d, l1, l2
        ret.push [l1, l2]
    return ret

  @define = (i, d, pairs, l1, l2) ->
    [s1, e1] = l1.split('.')
    [s2, e2] = l2.split('.')
    is_sym = (a, b) ->
      return pairs[a] is b or (pairs[a] is a and pairs[b] is b)
    if ((pairs[s1] is s2 and pairs[e1] is e2) or
        (pairs[s1] is e2 and pairs[e1] is s2) or
        (is_sym(s1, e1) and is_sym(s2, e2)))
      d.define ->
        Intersect "A#{i}", l1, l2
      pairs["A#{i}"] = "A#{i}"
    else
      pair = (l) -> l.split('.').map((x) -> pairs[x]).join('.')
      d.define =>
        Intersect "B#{i}", l1, l2
        Intersect "C#{i}", pair(l1), pair(l2)
      pairs["B#{i}"] = "C#{i}"
      pairs["C#{i}"] = "B#{i}"


exports.IntersectGen = IntersectGen