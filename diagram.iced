assert = require 'assert'
G = require 'geometry.js'

_diagram_ctx_g = null
Construction = (name, opts) ->
  opts.primitive ?= false
  opts.implicit_lines ?= -> []
  opts.canonicalize ?= (x) -> x

  return (args...) ->
    if args.length isnt opts.dep_types.length + 1
      throw new Error "Incorrect number of arguments for #{name} (expected #{dep_types.length + 1})"
    for arg in args
      if typeof arg isnt 'string'
        throw new Error "Arguments must be strings"

    console.log 'let', args[0], '=', name, args[1...]

    deps = opts.canonicalize args[1...]
    _diagram_ctx_g.add {
      name: args[0], type: name, deps: deps
      evaluator: opts.evaluator
      primitive: opts.primitive
      implicit_lines: opts.implicit_lines
    }

Pt = Construction 'Pt', {
  dep_types: []
  evaluator: (args...) -> new G.Point args...
  primitive: true
}

# Line = Construction 'Line', {
#   dep_types: [G.Point, G.Point]
#   evaluator: (args...) -> new G.Line args...
# }

Proj = Construction 'Proj', {
  dep_types: [G.Point, G.Line]
  evaluator: G.project_PL
  implicit_lines: -> [[@name, @deps[1]]]
}

Midpt = Construction 'Midpt', {
  dep_types: [G.Point, G.Point]
  canonicalize: (deps) -> deps.slice().sort()
  evaluator: G.midpt
  implicit_lines: -> [[@name, @deps[0] + '.' + @deps[1]]]
}

Intersect = Construction 'Intersect', {
  dep_types: [G.Line, G.Line]
  canonicalize: (deps) -> deps.slice().sort()
  evaluator: G.intersect_LL
  implicit_lines: -> [[@name, @deps[0]], [@name, @deps[1]]]
}

Circumcircle = Construction 'Circumcircle', {
  dep_types: [G.Point, G.Point, G.Point]
  canonicalize: (deps) -> deps.slice().sort()
  evaluator: G.circumcircle
}

IntersectPCC = Construction 'IntersectPCC', {
  dep_types: [G.Point, G.Circle, G.Circle]
  canonicalize: (deps) -> [deps[0]].concat(deps.slice(1, 3).sort())
  evaluator: G.intersect_PCC
}


class Diagram
  is_line = (name) -> '.' in name
  canonicalize = (line_name) ->
    [s, e] = line_name.split('.')
    if s < e
      return line_name
    return e + '.' + s

  constructor: ->
    @_items = {}
    @_implicit_lines = {}
    @_eval_order = []

  list_points: ->
    ret = []
    for k, v of @_items
      if v.primitive or v.type in ['Intersect', 'Proj', 'Midpt']
        ret.push v.name
    return ret

  # TODO: we should just make lines an entirely different kind of
  # object without deps
  ensure_line: (name) ->
    if not is_line(name)
      throw new Error "Invalid Line name #{name}"
    name = canonicalize name
    if not @_implicit_lines[name]?
      [start, end] = name.split('.')
      @_implicit_lines[name] = # TODO: temporary hack
        name: name, type: 'Line', deps: [start, end]
        evaluator: (args...) -> new G.Line args...
        primitive: false
        contains: []
    return @_implicit_lines[name]

  get: (name) ->
    if @_items[name]?
      return @_items[name]
    cname = canonicalize name
    return @_implicit_lines[cname] ? null

  add: (item) ->
    if @get(item.name)?
      # TODO: make exception for implicit lines?
      throw new Error "Name conflict #{item.name}"
    @_items[item.name] = item

    for dep in item.deps
      if is_line(dep)
        @ensure_line dep

    for [pt_name, line_name] in item.implicit_lines()
      line = @ensure_line line_name
      if pt_name in line.contains
        continue
      [ls, le] = line_name.split('.')
      for pt2 in [ls, le].concat(line.contains)
        c = canonicalize(pt_name + '.' + pt2)
        # TODO: make sure not to overwrite?
        @_implicit_lines[c] = line
      line.contains.push pt_name

    @_eval_order.push item.name

  define: (fn) -> # TODO: should only call once?
    assert not _diagram_ctx_g?
    _diagram_ctx_g = @
    fn()
    _diagram_ctx_g = null

  construct: (prims) ->
    console.log @

    extras = [] # for display only
    values = {}
    for name in @_eval_order
      item = @get name
      if item.primitive
        values[name] = item.evaluator prims[name]...
        continue

      dep_vals = []
      for d in item.deps
        # TODO: handle duplicate lines
        if not values[d]?
          assert is_line(d)
          [s, e] = @get(d).deps
          values[d] = G.Line values[s], values[e]
        dep_vals.push values[d]
      values[name] = item.evaluator dep_vals...

      if item.type is 'Midpt'
        # draw the segment for midpoints
        # TODO: dedup with lines
        [s, e] = (values[p] for p in item.deps)
        extras.push (G.Line s, e)

      if item.type is 'Proj'
        # draw the altitude for projections
        # TODO: dedup with lines
        extras.push (G.Line values[item.deps[0]], values[name])

    # fix lines to cover all contained points
    for k, v of values
      if not is_line(k) then continue
      [s, e] = (values[p] for p in @get(k).deps)
      pts = (values[p] for p in @get(k).contains).concat([s, e])
      v = e.minus(s)

      s = pts.reduce((a, b) -> if a.dot(v) < b.dot(v) then a else b)
      e = pts.reduce((a, b) -> if a.dot(v) > b.dot(v) then a else b)
      values[k] = G.Line s, e

    return {objs: values, extras: extras}


exports.Diagram = Diagram
for k, v of {Pt, Intersect, Proj, Midpt}
  exports[k] = v

