# Created by AshGillman 17/6/15

d3 = require 'd3'

# ColorBrewer defs: http://colorbrewer2.org/
cb_dark2 = ["#1b9e77","#d95f02","#7570b3","#e7298a","#66a61e","#e6ab02",
    "#a6761d","#666666"]
cb_pastel1 = ["#fbb4ae","#b3cde3","#ccebc5","#decbe4","#fed9a6","#ffffcc",
    "#e5d8bd","#fddaec","#f2f2f2"]
cb_RdYlBu = ["#a50026","#d73027","#f46d43","#fdae61","#fee090","#ffffbf",
    "#e0f3f8","#abd9e9","#74add1","#4575b4","#313695"]

bounds = (features) ->
  xs = []
  ys = []
  for f in features
    if f.geometry.type.toLowerCase() is 'polygon'
      for c in f.geometry.coordinates[0] # only outer polygon
        xs.push c[0]
        ys.push c[1]
    else if f.geometry.type.toLowerCase() is 'point'
      xs.push f.geometry.coordinates[0]
      ys.push f.geometry.coordinates[1]
  return [
      [(Math.min xs...), (Math.min ys...)],
      [(Math.max xs...), (Math.max ys...)]
    ]

do -> Array::filter ?= (callback) ->
  element for element in this when callback element

exports.FloorPlan = class FloorPlan
  constructor: (@svg) ->

  plotMap: (featureCollection) ->
    rooms = featureCollection.features.filter (f) ->
      f.properties?.type is 'room'
    sensors = featureCollection.features.filter (f) ->
      f.properties?.type is 'sensor'

    @._updateScales [rooms..., sensors...]
    @._plotRooms rooms
    @._plotSensors sensors

  _updateScales: (features) ->
    [[minX, minY], [maxX, maxY]] = bounds features
    width = @svg.attr "width"
    height = @svg.attr "height"

    @scaleX = (do d3.scale.linear)
        .domain [minX, maxX]
        .range [0, width]
    @scaleY = (do d3.scale.linear)
        .domain [minY, maxY]
        .range [height, 0]

    # Change scale of stretched axis to avoid stretching
    do =>
      dx = Math.abs (@scaleX 1) - (@scaleX 0)
      dy = Math.abs (@scaleY 1) - (@scaleY 0)
      if dx > dy
        @scaleX.domain [
            (@scaleX.invert 1/2*width - width * dx/dy/2),
            (@scaleX.invert 1/2*width + width * dx/dy/2)
          ]
      else if dy > dx
        @scaleY.domain [
            (@scaleY.invert 1/2*height + height * dy/dx/2),
            (@scaleY.invert 1/2*height - height * dy/dx/2)
          ]

  _plotRooms: (features) ->
    @svg.selectAll ".fp_room"
        .data features
      .enter()
        .append "polygon"
        .attr 'class', 'fp_room'
        .attr "points", (d) =>
          points =
            for p in d.geometry.coordinates[0]
              "#{Math.round(@scaleX p[0])},#{Math.round(@scaleY p[1])}"
          points.join ' '
        .style "fill", (d, i) -> cb_pastel1[i]

  _plotSensors: (features) ->
    # colour scale, domain is 20C-40C
    colours = cb_RdYlBu
    colourMapper = d3.scale.linear()
      .domain d3.range 20, 40, (40-20) / (colours.length - 1)
      .range colours

    sensor_sel = @svg.selectAll '.fp_sensor'
        .data features
    sensor_node_sel = sensor_sel.enter()
        .append 'g'
        .attr 'class', 'fp_sensor'
    sensor_node_sel.append 'circle'
        .attr 'class', 'fp_humidity'
        .attr 'r', '30'
        .attr 'fill-opacity', '0.5'
    sensor_node_sel.append 'circle'
        .attr 'class', 'fp_temperature'
        .attr 'r', '10'
    sensor_sel.select('.fp_humidity')
        .attr 'cx', (d) => Math.round @scaleX d.geometry.coordinates[0]
        .attr 'cy', (d) => Math.round @scaleY d.geometry.coordinates[1]
        .attr 'fill', (d) ->
          if d.properties?.humidities
            [..., current] = d.properties.humidities
            colourMapper current
          else
            'black'
    sensor_sel.select('.fp_temperature')
        .attr 'cx', (d) => Math.round @scaleX d.geometry.coordinates[0]
        .attr 'cy', (d) => Math.round @scaleY d.geometry.coordinates[1]
        .attr 'fill', (d) ->
          if d.properties?.temperatures
            [..., current] = d.properties.temperatures
            colourMapper current
          else
            'black'

exports.Sensors = class Sensors
  constructor: (@svg) ->
