assert = require 'assert'
{
  Diagram, Pt, Proj, Midpt, Intersect
} = require 'diagram.iced'
G = require 'geometry.js'

{IntersectGen} = require 'generator/intersect.iced'
{MidpointGen} = require 'generator/midpoints.iced'
{ProjGen} = require 'generator/proj.iced'

class GeoGen
  rand_int = (n) ->
    return Math.floor(Math.random() * n)

  rand_choice = (arr) ->
    assert arr.length > 0, "Can't choose from empty array!"
    return arr[rand_int arr.length]

  weighted_choice = (arr, wt_fn) ->
    wts = arr.map(wt_fn)
    total = wts.reduce((a, b) -> a + b)
    r = Math.random() * total
    for w, i in wts
      if r < w then return arr[i]
      r -= w
    return wts[wts.length - 1]

  constructor: ->
    @d = new Diagram
    @pairs = {}
    @iter = 0

  freshness_p: (pt) ->
    generation = if pt.length is 1
      0
    else
      parseInt pt[pt.length - 1] # TODO: handle multiple digits
    assert not isNaN generation
    return Math.exp generation

  freshness_l: (line) ->
    pts = line.split('.')
    return Math.max @freshness_p(pts[0]), @freshness_p(pts[1])

  generate: ->
    @d.define ->
      Pt 'A'; Pt 'B'; Pt 'C'
    @pairs = {A: 'A', B: 'C', C: 'B'}
    @iter = 0

    make_midpt = =>
      [a, b] = weighted_choice MidpointGen.list_candidates(@d), ([x, y]) =>
        Math.max @freshness_p(x), @freshness_p(y)
      #console.log 'defining midpt', a, b
      MidpointGen.define @iter, @d, @pairs, a, b
      @iter++
    make_proj = =>
      [p, l] = weighted_choice ProjGen.list_candidates(@d), ([x, y]) =>
        Math.max @freshness_p(x), @freshness_l(y)
      #console.log 'defining proj', p, l
      ProjGen.define @iter, @d, @pairs, p, l
      @iter++
    make_intersect = =>
      [l1, l2] = weighted_choice IntersectGen.list_candidates(@d), ([x, y]) =>
        Math.max @freshness_l(x), @freshness_l(y)
      #console.log 'defining intersect', l1, l2
      IntersectGen.define @iter, @d, @pairs, l1, l2
      @iter++

    make_midpt()
    make_proj()
    make_proj()
    make_intersect()
    make_midpt()





exports.GeoGen = GeoGen

# gg = new GeoGen
# gg.generate()
