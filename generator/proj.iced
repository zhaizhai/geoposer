assert = require 'assert'
{
  Diagram, Pt, Proj, Midpt, Intersect
} = require 'diagram.iced'
{ktuples} = require 'util.iced'
G = require 'geometry.js'

class ProjGen
  @is_candidate = (d, p, l) ->
    line = d.ensure_line(l)
    if p in line.contains.concat(line.deps)
      return false

    for k, v of d._items # TODO
      if v.type isnt 'Proj'
        continue
      if p is v.deps[0] and line is d.get(v.deps[1])
        return false
    return true

  @list_candidates = (d) ->
    ret = []
    pts = d.list_points()
    for triple in ktuples(pts, 3)
      for i in [0...3]
        [p, x, y] = triple.slice(i).concat(triple.slice(0, i))
        # console.log 'pxy', p, x, y
        l = [x, y].sort().join('.')
        if @is_candidate d, p, l
          ret.push [p, l] # TODO: watch out for dups?
    return ret

  @define = (i, d, pairs, p, l) ->
    [a, b] = l.split('.')
    if pairs[p] is p and pairs[a] is b
      d.define ->
        Proj "A#{i}", p, l
      pairs["A#{i}"] = "A#{i}"
    else
      d.define =>
        Proj "B#{i}", p, l
        Proj "C#{i}", pairs[p], pairs[a] + '.' + pairs[b]
      pairs["B#{i}"] = "C#{i}"
      pairs["C#{i}"] = "B#{i}"

exports.ProjGen = ProjGen