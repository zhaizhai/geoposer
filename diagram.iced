assert = require 'assert'
G = require 'geometry.js'

_diagram_ctx_g = null
Construction = (name, opts) ->
  opts.primitive ?= false
  opts.containments ?= -> []
  opts.canonicalize ?= (x) -> x
  for k in ['type', 'evaluator', 'dep_types']
    assert opts[k]?

  return (args...) ->
    if args.length isnt opts.dep_types.length + 1
      throw new Error "Incorrect number of arguments for #{name} (expected #{dep_types.length + 1})"
    for arg in args
      if typeof arg isnt 'string'
        throw new Error "Arguments must be strings"

    console.log 'let', args[0], '=', name, args[1...]

    deps = opts.canonicalize args[1...]
    _diagram_ctx_g.add {
      name: args[0], type: opts.type, deps: deps
      construction_type: name,
      evaluator: opts.evaluator
      primitive: opts.primitive
      containments: opts.containments
    }

Pt = Construction 'Pt', {
  type: G.Point
  dep_types: []
  evaluator: (args...) -> new G.Point args...
  primitive: true
}

Proj = Construction 'Proj', {
  type: G.Point
  dep_types: [G.Point, G.Line]
  evaluator: G.project_PL
  containments: -> [[@name, @deps[1]]]
}

Midpt = Construction 'Midpt', {
  type: G.Point
  dep_types: [G.Point, G.Point]
  canonicalize: (deps) -> deps.slice().sort()
  evaluator: G.midpt
  containments: -> [[@name, @deps[0] + '.' + @deps[1]]]
}

Intersect = Construction 'Intersect', {
  type: G.Point
  dep_types: [G.Line, G.Line]
  canonicalize: (deps) -> deps.slice().sort()
  evaluator: G.intersect_LL
  containments: -> [[@name, @deps[0]], [@name, @deps[1]]]
}

Circumcircle = Construction 'Circumcircle', {
  type: G.Circle
  dep_types: [G.Point, G.Point, G.Point]
  canonicalize: (deps) -> deps.slice().sort()
  evaluator: G.circumcircle
  containments: -> ([d, @name] for d in @deps)
}

IntersectPLC = Construction 'IntersectPLC', {
  type: G.Point
  dep_types: [G.Point, G.Line, G.Circle]
  evaluator: G.intersect_PLC
  containments: -> [[@name, @deps[1]], [@name, @deps[2]]]
}

# IntersectPCC = Construction 'IntersectPCC', {
#   dep_types: [G.Point, G.Circle, G.Circle]
#   canonicalize: (deps) -> [deps[0]].concat(deps.slice(1, 3).sort())
#   evaluator: G.intersect_PCC
# }


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
      if v.type is G.Point
        ret.push v.name
    return ret

  # TODO: reconsider ensure_line vs. get
  ensure_line: (name) ->
    if not is_line(name)
      throw new Error "Invalid Line name #{name}"
    name = canonicalize name
    if not @_implicit_lines[name]?
      [start, end] = name.split('.')
      @_implicit_lines[name] =
        name: name, type: G.Line
        construction_type: 'Implicit' # TODO
        contains: [start, end]
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

    if item.type is G.Circle
      item.contains = []
    @_items[item.name] = item

    for dep in item.deps
      if is_line(dep)
        @ensure_line dep

    for [pt_name, parent_name] in item.containments()
      if is_line(parent_name)
        line = @ensure_line parent_name
        if pt_name in line.contains
          continue
        for pt2 in line.contains
          c = canonicalize(pt_name + '.' + pt2)
          if @_implicit_lines[c]?
            # console.log 'bad line', line
            # console.log 'alt', @_implicit_lines[c]
            # TODO: right now this can happen if we define the same
            # intersection twice (using different names for the same
            # lines)
            console.warn "Duplicate implicit line #{c}!"
          @_implicit_lines[c] = line
        line.contains.push pt_name

      else
        parent = @get parent_name
        assert parent.type is G.Circle
        if pt_name not in parent.contains
          parent.contains.push pt_name

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
    lines_used = []

    eval_line = (line_name) =>
      [s, e] = line_name.split('.')
      return G.Line values[s], values[e]

    for name in @_eval_order
      if is_line(name)
        assert false, "Don't support non-implicit lines right now"
        continue

      item = @get name
      if item.primitive
        assert prims[name]?, "Unspecified value for #{name}"
        values[name] = item.evaluator prims[name]...
        continue

      dep_vals = []
      for d in item.deps
        # TODO: handle duplicate lines
        if values[d]?
          dep_vals.push values[d]
        else
          assert is_line(d)
          l = @get(d)
          if l not in lines_used then lines_used.push l
          dep_vals.push eval_line(d)
      values[name] = item.evaluator dep_vals...

      if item.construction_type is 'Midpt'
        # draw the segment for midpoints
        # TODO: dedup with lines
        [s, e] = (values[p] for p in item.deps)
        extras.push (G.Line s, e)

      if item.construction_type is 'Proj'
        # draw the altitude for projections
        # TODO: dedup with lines
        extras.push (G.Line values[item.deps[0]], values[name])

    # fix lines to reach all points that lie on them
    for l in lines_used
      pts = (values[p] for p in l.contains)
      v = pts[1].minus(pts[0]) # TODO: make sure v isn't 0
      s = pts.reduce((a, b) -> if a.dot(v) < b.dot(v) then a else b)
      e = pts.reduce((a, b) -> if a.dot(v) > b.dot(v) then a else b)
      values[l.name] = G.Line s, e

    return {objs: values, extras: extras}


exports.Diagram = Diagram
for k, v of {
  Pt, Intersect, Proj, Midpt,
  Circumcircle, IntersectPLC
}
  exports[k] = v

