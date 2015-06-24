# Created by AshGillman, 19/5/14
TS = require './thingspeak'
D3P = require './D3Plotter.coffee'
LineChart = require('./NvWrapper').LineChart
DataMgr = require('./DataManager').DataManager
FloorPlan = require('./FloorPlan').FloorPlan
$ = require 'jquery'

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
    tooltip = d3.select 'body'
        .append 'div'
        .attr 'class', 'tooltip'
        .attr 'id', 'fp_tip'
        .style 'opacity', 0
    plan = new FloorPlan svg

    map_features =
      type: 'FeatureCollection'
      features: []

    addFeatureCollection = (featureCollection) ->
      if !featureCollection.features
        console.error "loaded invalid feature collection"

      # add to map_features, update plot
      map_features.features.push f for f in featureCollection.features
      plan.plotMap map_features

      # just a worker to create a closure over the channel
      updateCallback = (sensor) ->
        dataMgr = new DataMgr
        dataMgr
          .setSource (callback) ->
            TS.loadFeed sensor.properties.channel, ((d) -> callback TS.toNv d)
          .addSubscriber (data) ->
            console.log data
            sensor.properties.temperatures = (d.y for d in data[0].values)
            sensor.properties.humidities = (d.y for d in data[1].values)
            sensor.properties.th_times = (d.x for d in data[0].values)
            console.log sensor.properties
            plan.plotMap map_features
          .begin()
      # updaters for any sensors
      for sensor in FloorPlan.filterSensorFeatures featureCollection.features
        updateCallback sensor

    load_map_features = (url) ->
      $.getJSON url, (data) ->
          addFeatureCollection data
        .fail ->
          console.error "couldn't load map data: #{url}"

    load_map_features '/data/floor_0.geojson'
    load_map_features '/data/sensors.geojson'

module.exports = App
