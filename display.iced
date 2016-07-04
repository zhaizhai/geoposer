SVG = require 'lib/svg.coffee'
Path = require 'paths-js/path'
{
  Diagram, Pt, Proj, Midpt, Intersect,
  Circumcircle, IntersectPLC
} = require 'diagram.iced'
G = require 'geometry.js'

{GeoGen} = require 'generator.iced'

render = (item, opts = {}) ->
  if item.constructor.name is 'Point'
    return SVG.circle {r: 4, cx: item.x, cy: item.y}

  if item.constructor.name is 'Circle'
    return SVG.circle {
      r: item.r, cx: item.c.x, cy: item.c.y
      fill: 'none', 'stroke-width': 3, stroke: 'black'
    }

  if item.constructor.name is 'Line'
    {s, e} = item
    path = Path().moveto(s.x, s.y).lineto(e.x, e.y)
    if opts.dotted
      return SVG.path {
        d: path.print(), 'stroke-width': 2
        stroke: 'blue', 'stroke-dasharray': '3,3'
      }
    else
      return SVG.path {
        d: path.print(), 'stroke-width': 3
        stroke: 'black'
      }

  throw new Error "Unable to render this item: #{item}"

render_diagram = (root, diagram, params) ->
  {objs, extras} = diagram.construct params
  children = (render(v) for k, v of objs)
  children = children
    .concat(render(v, {dotted: true}) for v in extras)
  root.appendChild (SVG.g {
    transform: "translate(250, 250)"
  }, children)

render_symmetries = (root, diagram) ->
  labels = ['A', 'B', 'C']
  values = [[80, 120], [0, 0], [200, 0]]
  for i in [0...3]
    params = {}
    for j in [0...3]
      params[labels[j]] = values[(j + i) % 3]
    render_diagram root, diagram, params



generate_problem = ->
  depth = 5

  for i in [0...1000]
    gg = new GeoGen
    gg.generate()
    D = gg.d
    pt_name = 'A' + (depth - 1)

    if not D.get(pt_name)? then continue

    pts = [[80, 120], [0, 0], [200, 0]]
    cons = []

    for j in [0...3]
      params =
        A: pts[j], B: pts[(j + 1)%3], C: pts[(j + 2)%3]
      {objs, extras} = D.construct params
      cons.push {P: objs['A'], Q: objs[pt_name]}

    if cons[0].Q.dist(cons[1].Q) <= 0.001
      continue

    lines = []
    for j in [0...3]
      lines.push G.Line(cons[j].P, cons[j].Q)
    console.log 'lines', lines
    if G.are_concurrent(lines...)
      return D

  throw new Error "Failed to generate problem in 1000 tries :("


window.onload = ->
  root = SVG.root 500, 500
  $('body').append $(root)

  # diagram = new Diagram
  # diagram.define ->
  #   Pt 'A'; Pt 'B'; Pt 'C'
  #   Proj 'E', 'B', 'A.C'
  #   Proj 'F', 'C', 'A.B'
  #   Midpt 'M', 'B', 'C'
  #   Circumcircle 'w', 'E', 'F', 'M'
  #   IntersectPLC 'Z', 'M', 'M.B', 'w'
  # render_diagram root, diagram, {
  #   A: [80, 120], B: [0, 0], C: [200, 0]
  # }

  diagram = generate_problem()
  render_symmetries root, diagram


