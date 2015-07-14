# Created by AshGillman, 19/5/15
TS = require '../thingspeak'
D3P = require '../D3Plotter.coffee'
LineChart = require('../NvWrapper').LineChart
DataMgr = require('../DataManager').DataManager
FloorPlan = require('../FloorPlan').FloorPlan
StatusDrawer = require('./StatusDrawer')
$ = require 'jquery'

anchorId = 'vis'
#mainAnchor = D3P.appendAnchor('body', anchorId)

# Prototype updaters
do -> Array::last ?= -> @[@length - 1]
do -> Array::unique ?= ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output
do -> Array::filter ?= (callback) ->
  element for element in this when callback element
do -> Function::debounce ?= (threshold=100, execAsap=true) ->
  fn = @
  console.log @
  timeout = undefined
  debounced = ->
    delayed = ->
      fn.apply obj, args  unless execAsap
      timeout = null
      return
    obj = @
    args = arguments
    if timeout
      clearTimeout timeout
    else func.apply obj, args if execAsap
    timeout = setTimeout(delayed, threshold)
    return

# inline debugger
addDebug = (fn) -> (d...) ->
  console.log fn, d
  fn d...

# helper functions
floor_of = (sensor) -> sensor.geometry.coordinates[2]

App =
  start: ->
    do App.display_overview

  display_overview: ->
    $.getJSON '../data/sensors.geojson', (sensor_metadata) ->
        svg = d3.select '#vis svg'
          .style 'height', '80vh'
        parent = svg

        histories =
          'day': {days: 1, average: 10}
          'week': {days: 7, average: 60}
          'month': {days: 31, average: 240}
        get_history = -> histories[(d3.select '#history').property 'value']
        history = do get_history

        disp_window = new StatusDrawer svg, sensor_metadata, history
        d3.select '#history'
          .on 'change', ->
            history = do get_history
            disp_window.update_history history
        $(window).resize (do disp_window.redraw).debounce 500, false
      .fail ->
        console.error "couldn't load map data: /data/sensors.geojson"

  display_floorplan: ->
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
            #console.log data
            sensor.properties.temperatures = (d.y for d in data[0]?.values)
            sensor.properties.humidities = (d.y for d in data[1]?.values)
            sensor.properties.th_times = (d.x for d in data[0]?.values)
            #console.log sensor.properties
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
