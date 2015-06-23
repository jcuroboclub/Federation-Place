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
    ###
    mainChart = new LineChart('#' + anchorId + ' svg')
    dataMgr = new DataMgr
    dataMgr.setSource (callback) ->
        TS.loadFeed channelid, (d) ->
          callback(TS.toNv(d))
      .addSubscriber mainChart.updateChart
      .begin()
    ###

    width = 512
    height = 512
    svg = d3.select '#vis svg'
        .attr 'width', width
        .attr 'height', height
    plan = new FloorPlan.FloorPlan svg

    map_features =
      type: 'FeatureCollection'
      features: []

    load_map_features = (url) ->
      $.getJSON url, (data) ->
          if !data.features
            console.error "loaded invalid data: #{url}"
          map_features.features.push f for f in data.features
          plan.plotMap map_features
        .fail ->
          console.error "couldn't load map data: #{url}"

    load_map_features '/data/floor_0.geojson'
    load_map_features '/data/sensors.geojson'

module.exports = App
