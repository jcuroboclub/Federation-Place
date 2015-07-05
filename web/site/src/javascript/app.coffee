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
do -> Array::filter ?= (callback) ->
    element for element in this when callback(element)

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
    $.getJSON './data/sensors.geojson', (sensor_metadata) ->
        sensors = sensor_metadata.features
        floors = do (floor_of s for s in sensors).unique
        sensors_by_floor =
          for f in floors
            sensors.filter (s) ->
              (floor_of s) == f

        svg = d3.select '#vis svg'
          .style 'height', '80vh'
        parent = svg

        # sizing for each node
        floor_title_height = 40
        node_h_spacing = +(parent.style 'width')[0..-3] / floors.length
        node_v_spacing = (+(parent.style 'height')[0..-3] /
          Math.max (s.length for s in sensors_by_floor)...) - floor_title_height

        # aspect ratio
        w_h_ratio = 4
        if node_h_spacing > node_v_spacing*w_h_ratio
          node_h_spacing = node_v_spacing*w_h_ratio
        if node_v_spacing > node_h_spacing/w_h_ratio
          node_v_spacing = node_h_spacing/w_h_ratio

        node_h_margin = 20
        node_v_margin = 10
        node_width = node_h_spacing - node_h_margin
        node_height = node_v_spacing - node_v_margin

        temp_charts = {}
        hum_charts = {}

        parent.selectAll '.floor_title'
            .data floors
          .enter()
            .append 'text'
            .attr 'class', 'floor_title'
            .attr 'dy', '1em'
            .text (d) -> "Floor #{d}"
            .attr "x", (d) -> (floors.indexOf d)*node_h_spacing

        bind_dataMgr_to_sensor = (sensor) ->
          dataMgr = new DataMgr
          dataMgr
            .setSource (callback) ->
              TS.loadFeed sensor.properties.channel, ((d) -> callback TS.toNv d), 2000
            .addSubscriber (data) ->
              # Add latest data to the sensor object
              sensor.properties.temperatures = (d.y for d in data[0].values)
              sensor.properties.humidities = (d.y for d in data[1].values)
              sensor.properties.th_times = (d.x for d in data[0].values)
              sensor.properties.nvData = data

              # svg:g container for each sensor
              sensor_sel = parent.selectAll '.sensor'
                .data sensors
              sensor_enter = sensor_sel.enter()
                .append 'g'
                .attr 'class', 'sensor'
                .attr "transform", (d) ->
                  "translate(#{(floors.indexOf floor_of d)*node_h_spacing},
                  #{floor_title_height + node_v_spacing *
                  (sensors_by_floor[floors.indexOf floor_of d].indexOf d)})"

              # Textual current data for each sensor
              sensor_data = sensor_enter.append 'text'
                .attr 'class', 'status'
                .attr 'dy', '1em'
              sensor_sel.select '.status'
                .text (d) ->
                  "#{d.properties.description}:
                  #{do d.properties.temperatures.last}ºC,
                  #{do d.properties.humidities.last}% humidity"
              text_height = +(sensor_sel.select('.status').style 'height')[0..-3]

              # Temperature history plot
              sensor_enter.append 'g'
                .attr 'class', 'temp_history'
                .each (d) ->
                  temp_chart = new LineChart d3.select @
                  temp_chart.chart
                    .margin {bottom: 0, right: 30}
                    .showLegend? false
                    .useInteractiveGuideline? false
                  temp_charts[d.properties.id] = temp_chart
              sensor_sel.select '.temp_history'
                .attr "transform",
                  "translate(0,#{text_height-15})"
                .each (d) ->
                  temp_chart = temp_charts[d.properties.id]
                  temp_chart.chart
                    .width node_width/2
                    .height node_height - text_height - 5
                  temp_chart.updateChart [d.properties.nvData?[0]]

              # Humidity history plot
              sensor_enter.append 'g'
                .attr 'class', 'hum_history'
                .each (d) ->
                  hum_chart = new LineChart d3.select @
                  hum_chart.chart
                    .margin {bottom: 0, right: 30}
                    .showLegend? false
                    .useInteractiveGuideline? false
                  hum_charts[d.properties.id] = hum_chart
              sensor_sel.select '.hum_history'
                .attr "transform",
                  "translate(#{node_width / 2},
                  #{text_height-15})"
                .each (d) ->
                  hum_chart = hum_charts[d.properties.id]
                  hum_chart.chart
                    .width node_width/2
                    .height node_height - text_height - 5
                  hum_chart.updateChart [d.properties.nvData?[1]]

          .begin()
        bind_dataMgr_to_sensor sensor for sensor in sensors
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
