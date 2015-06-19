# Created by AshGillman 17/6/15

d3 = require 'd3'

# ColorBrewer defs: http://colorbrewer2.org/
cb_dark2 = ["#1b9e77","#d95f02","#7570b3","#e7298a","#66a61e","#e6ab02",
    "#a6761d","#666666"]

bounds = (featureCollection) ->
  #console.log featureCollection
  #console.log f.geometry.coordinates[0] for f in featureCollection.features
  xs = []
  ys = []
  for f in featureCollection.features
    for c in f.geometry.coordinates[0]
      xs.push c[0]
      ys.push c[1]
  return [
      [(Math.min xs...), (Math.min ys...)],
      [(Math.max xs...), (Math.max ys...)]
    ]

exports.FloorPlan = class FloorPlan
  constructor: (@svg) ->
    @projection = (do d3.geo.mercator)
        .scale 20
        .center [0.5, 0.5]
    @path = (do d3.geo.path)
      .projection @projection

  plotMap: (featureCollection) ->
    [[minX, minY], [maxX, maxY]] = bounds featureCollection
    width = @svg.attr "width"
    height = @svg.attr "height"

    scaleX = (do d3.scale.linear)
        #.interpolate d3.interpolateRound
        .domain [minX, maxX]
        .range [1e-6, width]
    scaleY = (do d3.scale.linear)
        #.interpolate d3.interpolateRound
        .domain [minY, maxY]
        .range [height, 1e-6]

    # Change scale of stretched axis to avoid stretching
    dx = Math.abs((scaleX 1) - (scaleX 0))
    dy = Math.abs((scaleY 1) - (scaleY 0))
    if dx > dy
      scaleX.domain [
          (scaleX.invert 1/2*width - width * dx/dy/2),
          (scaleX.invert 1/2*width + width * dx/dy/2)
        ]
    else if dy > dx
      scaleY.domain [
          (scaleY.invert 1/2*height + height * dy/dx/2),
          (scaleY.invert 1/2*height - height * dy/dx/2)
        ]

    @svg.selectAll "polygon"
        .data featureCollection.features
      .enter()
        .append "polygon"
        .attr "class", "feature"
        .attr "points", (d) ->
          points =
            for p in d.geometry.coordinates[0]
              "#{Math.round(scaleX p[0])},#{Math.round(scaleY p[1])}"
          points.join ' '
        .style("fill", (d, i) -> cb_dark2[i] )
