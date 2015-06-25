# Created by AshGillman, 19/5/14
TS = require './thingspeak'
D3P = require './D3Plotter.coffee'
LineChart = require('./NvWrapper').LineChart
DataMgr = require('./DataManager').DataManager
FloorPlan = require('./FloorPlan').FloorPlan
$ = require 'jquery'

anchorId = 'vis'
#mainAnchor = D3P.appendAnchor('body', anchorId)

# Prototype updaters
do -> Array::last ?= -> @[@length - 1]
do -> Array::unique ?= ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output

# inline debugger
addDebug = (fn) -> (d...) ->
  console.log fn, d
  fn d...

App =
  start: ->
    do App.display_overview

  display_overview: ->
    $.getJSON '/data/sensors.geojson', (sensor_metadata) ->
        floors = do (s.geometry.coordinates[2] for s in sensor_metadata.features).unique

        sensor = sensor_metadata.features[0] # TODO for each
        svg = d3.select '#vis svg'
          .style 'height', '100vh'
        parent = svg

        dataMgr = new DataMgr
        dataMgr
          .setSource (callback) ->
            TS.loadFeed sensor.properties.channel, ((d) -> callback TS.toNv d)
          .addSubscriber (data) ->
            sensor.properties.temperatures = (d.y for d in data[0].values)
            sensor.properties.humidities = (d.y for d in data[1].values)
            sensor.properties.th_times = (d.x for d in data[0].values)

            # svg:g container for each sensor
            sensor_sel = parent.selectAll '.sensor'
              .data [sensor]
            sensor_enter = sensor_sel.enter()
              .append 'g'
              .attr 'class', 'sensor'

            # Textual current data for each sensor
            sensor_data = sensor_enter.append 'text'
              .attr 'class', 'status'
              .attr 'dy', '1em'
            sensor_sel.select '.status'
              .text (d) ->
                "#{d.properties.description}:
                #{do d.properties.temperatures.last}ºC,
                #{do d.properties.humidities.last}% humidity"

            # Temperature history plot
            temp_chart = null
            sensor_enter.append 'g'
              .attr 'class', 'temp_history'
              .call -> temp_chart = new LineChart sensor_sel.select '.temp_history'
            sensor_sel.select '.temp_history'
              .attr "transform",
                "translate(0,#{(+(sensor_sel.select('.status').style 'height')[0..-3])-15})"
            temp_chart.chart
              .width +((svg.style 'width')[0..-3]) / floors.length / 2
              .height '150'
              .showLegend? false
              .useInteractiveGuideline? false
            temp_chart.updateChart [data[0]]

            # Humidity history plot
            hum_chart = null
            sensor_enter.append 'g'
              .attr 'class', 'hum_history'
              .call -> hum_chart = new LineChart sensor_sel.select '.hum_history'
            sensor_sel.select '.hum_history'
              .attr "transform",
                "translate(#{+((svg.style 'width')[0..-3]) / floors.length / 2},
                #{(+(sensor_sel.select('.status').style 'height')[0..-3])-15})"
            hum_chart.chart
              .width +((svg.style 'width')[0..-3]) / floors.length / 2
              .height '150'
              .showLegend? false
              .useInteractiveGuideline? false
            hum_chart.updateChart [data[1]]

          .begin()
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
            sensor.properties.temperatures = (d.y for d in data[0].values)
            sensor.properties.humidities = (d.y for d in data[1].values)
            sensor.properties.th_times = (d.x for d in data[0].values)
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
