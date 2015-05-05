# Created by AshGillman, 26/04/15

d3 = require 'd3'
require 'nvd3/build/nv.d3.js'

exports.redraw = (elem, chart, data) ->
  d3.select(elem).datum(data).call chart

exports.appendAnchor = (to, id) ->
  p = d3.select(to).append("p").attr("id", id)
  svg = p.append("svg")
  return svg
