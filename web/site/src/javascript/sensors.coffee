TS = require './thingspeak'
DataMgr = require('./DataManager').DataManager
$ = require 'jquery'

d3 = require 'd3'
require 'nvd3/build/nv.d3.js' # as nv

sensors = [
  {location:"Bronson's office", channelID:42694},
  {location:"14-101 lab", channelID:42698}
]

createChart = (sensor) ->
  console.log sensor

  # Create the <svg> tag for this chart
  svg = d3.select("#vis").append("svg")

  # Create the chart
  chart = nv.models.lineChart()
  chart.useInteractiveGuideline(true)
  chart.xAxis.axisLabel('Time').tickFormat (d) ->
    d3.time.format('%H:%M') new Date(d)
  chart.yAxis.axisLabel('Temp (C)').tickFormat d3.format('.1f')
  nv.utils.windowResize chart.update

  # Set up live data updates
  dataMgr = new DataMgr
  dataMgr
    .setSource (callback) ->
      TS.loadFeed sensor.channelID, (d) ->
        callback(TS.toNv(d))
    .addSubscriber (d) ->
      console.log d
      svg
        .datum([d[0]])
        .transition().duration(500)
        .call(chart)
    .begin()


start = () ->
  createChart(sensor) for sensor in sensors


start()
