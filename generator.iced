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

  constructor: ->
    @d = new Diagram
    @pairs = {}

  generate: ->
    @d.define ->
      Pt 'A'; Pt 'B'; Pt 'C'
    @pairs.A = 'A'
    @pairs.B = 'C'
    @pairs.C = 'B'

    make_midpt = =>
      [a, b] = rand_choice MidpointGen.list_candidates(@d)
      #console.log 'defining midpt', a, b
      MidpointGen.define i, @d, @pairs, a, b
    make_proj = =>
      [p, l] = rand_choice ProjGen.list_candidates(@d)
      #console.log 'defining proj', p, l
      ProjGen.define i, @d, @pairs, p, l
    make_intersect = =>
      [l1, l2] = rand_choice IntersectGen.list_candidates(@d)
      #console.log 'defining intersect', l1, l2
      IntersectGen.define i, @d, @pairs, l1, l2

    i = 0
    make_midpt(); i++
    make_proj(); i++
    make_proj(); i++
    make_intersect(); i++
    make_midpt(); i++





exports.GeoGen = GeoGen

# gg = new GeoGen
# gg.generate()
