# Created by AshGillman, 19/5/14
TS = require './ThingSpeak'
D3P = require './D3Plotter.coffee'
LineChart = require('./NvWrapper').LineChart
DataMgr = require('./DataManager').DataManager
FloorPlan = require './FloorPlan'
$ = require 'jquery'

channelid = 20466 # 33970
anchorId = 'vis'
#mainAnchor = D3P.appendAnchor('body', anchorId)

addDebug = (fn) -> (d...) ->
  console.log fn, d
  fn d...

App =
  start: ->
    mainChart = new LineChart('#' + anchorId + ' svg')
    dataMgr = new DataMgr
    dataMgr.setSource (callback) ->
        TS.loadFeed channelid, (d) ->
          callback(TS.toNv(d))
      .addSubscriber mainChart.updateChart
      .begin()

    width = 512
    height = 512
    svg = d3.select("body").append("svg")
        .attr("width", width)
        .attr("height", height)
    plan = new FloorPlan.FloorPlan(svg)

    $.getJSON "/data/floor_0.geojson", (data, err) ->
      if err
        console.error err
      plan.plotMap(data)


module.exports = App
