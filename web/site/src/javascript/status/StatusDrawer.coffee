# Created by AshGillman, 12/07/15
TS = require '../thingspeak'
DataMgr = require('../DataManager').DataManager
LineChart = require('../NvWrapper').LineChart


# constants/magic numbers
floor_title_height = 40 # height of the floor title
node_w_h_ratio = 3 # desired aspect ratio (width:height) of each node
node_h_margin = 20 # horizontal margin between nodes
node_v_margin = 40 # vertical margin between nodes
n_samples = 1000 # no. samples to download from ThingSpeak


# Prototype updaters
do -> Array::last ?= -> @[@length - 1]
do -> Array::unique ?= ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output
do -> Array::filter ?= (callback) ->
  element for element in this when callback element
do -> Array::sum ?= -> @reduce ((a, b) -> a + b), 0
do -> Array::average ?= -> if @length then do @sum / @length else 0


# helper functions
floor_of = (sensor) -> sensor.geometry.coordinates[2]
id_of = (sensor) -> sensor.properties.id
svg_px_width = (el) -> +(el.style 'width')[0..-3]
svg_px_height = (el) -> +(el.style 'height')[0..-3]
comfort_desc = (comf) ->
  return 'unrated'            if not comf
  return 'very uncomfortable' if 1   <= comf <  1.3
  return 'uncomfortable'      if 1.3 <  comf <  1.7
  return 'indecisive'         if 1.7 <  comf <  2.3
  return 'comfortable'        if 2.3 <  comf <  2.7
  return 'very comfortable'   if 2.7 <  comf <= 3
  return '<error>'


StatusDrawer = class StatusDrawer
  constructor: (@parent, sensor_metadata) ->
    @sensors = sensor_metadata.features
    @floors = do (floor_of s for s in @sensors).unique
    @sensors_by_floor =
      for f in @floors
        @sensors.filter (s) ->
          (floor_of s) == f

    @temp_charts = {}
    @hum_charts = {}
    @env_dataMgrs = {}
    @comf_dataMgrs = {}

    do @.fit_tiling
    do @.draw_floor_titles
    @_bind_dataMgr_to_sensor sensor for sensor in @sensors

  fit_tiling: ->
    # sizing for each node
    @node_h_spacing = (svg_px_width @parent) / @floors.length
    most_sensors_per_floor = Math.max (s.length for s in @sensors_by_floor)...
    @node_v_spacing = ((svg_px_height @parent) / most_sensors_per_floor) -
      floor_title_height

    # aspect ratio
    if @node_h_spacing > @node_v_spacing * node_w_h_ratio
      @node_h_spacing = @node_v_spacing * node_w_h_ratio
    if @node_v_spacing > @node_h_spacing / node_w_h_ratio
      @node_v_spacing = @node_h_spacing / node_w_h_ratio

    @node_width = @node_h_spacing - node_h_margin
    @node_height = @node_v_spacing - node_v_margin

  draw_floor_titles: ->
    @parent.selectAll '.floor_title'
        .data @floors
      .enter()
        .append 'text'
        .attr 'class', 'floor_title'
        .attr 'dy', '1em'
        .text (d) -> "Floor #{d}"
        .attr "x", (floor) => (@floors.indexOf floor) * @node_h_spacing

  _bind_dataMgr_to_sensor: (sensor) ->
    if !@env_dataMgrs[id_of sensor]
      @env_dataMgrs[id_of sensor] = new DataMgr
      @env_dataMgrs[id_of sensor]
        .setSource (callback) ->
          TS.loadFeed sensor.properties.env_channel
          , ((d) -> callback TS.toNv d)
          , n_samples
        .addSubscriber (data) =>
          @_bind_env_data_to_sensor sensor, data
          do @_draw_node_status
      .begin()

    if !@comf_dataMgrs[id_of sensor]
      @comf_dataMgrs[id_of sensor] = new DataMgr
      @comf_dataMgrs[id_of sensor]
        .setSource (callback) ->
          TS.loadFeed sensor.properties.comf_channel
          , ((d) -> callback TS.toNv d)
          , n_samples
        .addSubscriber (data) =>
          @_bind_comf_data_to_sensor sensor, data
          do @_draw_node_status
      .begin()

  _bind_env_data_to_sensor: (sensor, nvData) ->
    sensor.properties.temperatures = (d.y for d in nvData[0].values)
    sensor.properties.humidities = (d.y for d in nvData[1].values)
    sensor.properties.th_times = (d.x for d in nvData[0].values)
    sensor.properties.env_nvData = nvData

  _bind_comf_data_to_sensor: (sensor, nvData) ->
    sensor.properties.comfortabilities = (d.y for d in nvData[0].values)
    sensor.properties.comf_times = (d.x for d in nvData[0].values)
    sensor.properties.comf_nvData = nvData

  _draw_node_status: ->
    # svg:g container for each sensor
    @sensor_sel = @parent.selectAll '.sensor'
      .data @sensors
    @sensor_enter = @sensor_sel.enter()
      .append 'g'
      .attr 'class', 'sensor'
      .attr "transform", (d) =>
        "translate(#{(@floors.indexOf floor_of d) * @node_h_spacing},
        #{floor_title_height + @node_v_spacing *
        (@sensors_by_floor[@floors.indexOf floor_of d].indexOf d)})"

    # Textual current data for each sensor
    @sensor_enter.append 'text'
      .attr 'class', 'status'
      .attr 'dy', '1em'
    @sensor_sel.select '.status'
      .each (d) ->
        text = "[#{id_of d}]: #{d.properties.description}\n
        #{do d.properties.temperatures.last}ºC,
        #{do d.properties.humidities.last}% humidity,
        #{comfort_desc (do d.properties.comfortabilities.average)}"
        console.log do d.properties.comfortabilities.average
        lines = text.split /\n/
        tspan = (d3.select @).selectAll 'tspan'
          .data lines
        tspan.enter()
          .append 'tspan'
          .attr 'x', 0
          .attr 'dy', '1.1em'
        tspan.text (d) -> d
    @text_height = svg_px_height @sensor_sel.select '.status'

    # Temperature history plot
    @_plot_mini_chart 'temp_history', @temp_charts, 0

    # Humidity history plot
    @_plot_mini_chart 'hum_history', @hum_charts, 1

  _plot_mini_chart: (chart_class, chart_dict, index) ->
    @sensor_enter.append 'g'
      .attr 'class', chart_class
      .each (d) ->
        chart = new LineChart d3.select @
        chart.chart
          .margin {bottom: 0, right: 30}
          .showLegend? false
          .useInteractiveGuideline? false
        chart_dict[id_of d] = chart
    @sensor_sel.select '.' + chart_class
      .attr "transform",
        "translate(#{index * @node_width / 2},#{@text_height})"
      .each (d) =>
        chart = chart_dict[id_of d]
        chart.chart
          .width @node_width / 2
          .height @node_height - @text_height - 5
        chart.updateChart [d.properties.env_nvData?[index]]


module.exports = StatusDrawer