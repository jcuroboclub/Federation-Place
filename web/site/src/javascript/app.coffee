# Created by AshGillman, 19/5/14

_ = require 'underscore'
$ = require 'jquery'
d3 = require 'd3'
require 'nvd3/build/nv.d3.js'
ts = require './thingspeak'

channelid = 33970
spineData = []


# Date formatting
formatHours = (d) ->
  d3.time.format('%H:%M') new Date(d)

lineChart = ->
  chart = nv.models.lineWithFocusChart()
  #.useInteractiveGuideline(true)
  chart.xAxis.axisLabel('Time').tickFormat formatHours
  chart.x2Axis.tickFormat formatHours
  chart.yAxis.axisLabel('Temp (C)').tickFormat d3.format('.1f')
  chart.yAxis.tickFormat d3.format('.1f')
  #chart.useInteractiveGuideline(true);
  nv.utils.windowResize chart.update
  chart

loadGraph = (chart, data) ->
  d3.select('#nvd3 svg').datum(data).call chart
  chart

updatePlot = (chart) ->
  $.getJSON 'http://api.thingspeak.com/channels/' +
      channelid + '/feed.json?', (data) ->
    spineData = ts.toNvLine(data)
    loadGraph chart, spineData
    console.log 'plot'
    return
  return

#$(document).ready ->
#  updatePlot()
#  # check for new updates
#  setInterval 'updatePlot()', 15000
#  return

App =
  start: ->
    console.log "app started!"
    spineChart = lineChart()
    updatePlot(spineChart)
    setInterval (do (spineChart) -> -> updatePlot(spineChart)), 15000

module.exports = App