# Created by AshGillman, 12/07/15
__ = require '../helpers'
TS = require '../thingspeak'
DataMgr = require('../DataManager').DataManager
LineChart = require('../NvWrapper').LineChart


# constants/magic numbers
floor_title_height = 30 # height of the floor title
node_w_h_ratio = 3 # desired aspect ratio (width:height) of each node
node_h_margin = 20 # horizontal margin between nodes
node_v_margin = 40 # vertical margin between nodes
n_samples = 1000 # no. samples to download from ThingSpeak


StatusDrawer = class StatusDrawer
  constructor: (@parent, sensor_metadata, @ts_params) ->
    @sensors = sensor_metadata.features
    @floors = do (__.floor_of s for s in @sensors).unique
    @sensors_by_floor =
      for f in @floors
        @sensors.filter (s) -> (__.floor_of s) == f

    @temp_charts = {}
    @hum_charts = {}
    @env_dataMgrs = {}
    @comf_dataMgrs = {}

    do do @redraw

  # NOTE: returns a closure
  redraw: ->
    context = @
    return ->
      do context._fit_tiling
      do context._draw_floor_titles
      context._bind_dataMgr_to_sensor sensor for sensor in context.sensors

  _fit_tiling: ->
    # sizing for each node
    @node_h_spacing = (__.svg_px_width @parent) / @floors.length
    most_sensors_per_floor = Math.max (s.length for s in @sensors_by_floor)...
    @node_v_spacing = ((__.svg_px_height @parent) / most_sensors_per_floor) -
      floor_title_height

    # aspect ratio
    if @node_h_spacing > @node_v_spacing * node_w_h_ratio
      @node_h_spacing = @node_v_spacing * node_w_h_ratio
    if @node_v_spacing > @node_h_spacing / node_w_h_ratio
      @node_v_spacing = @node_h_spacing / node_w_h_ratio

    @node_width = @node_h_spacing - node_h_margin
    @node_height = @node_v_spacing - node_v_margin

  _draw_floor_titles: ->
    sel = @parent.selectAll '.floor_title'
      .data @floors
    sel.enter()
      .append 'text'
      .attr 'class', 'floor_title'
      .attr 'dy', '1em'
    sel
      .text (d) -> "Floor #{d}"
      .attr "x", (floor) => (@floors.indexOf floor) * @node_h_spacing

  update_history: (@ts_params) ->
    for sensor in @sensors
      @_update_source sensor
      do @env_dataMgrs[__.id_of sensor].update
      do @comf_dataMgrs[__.id_of sensor].update

  _update_source: (sensor) ->
    @env_dataMgrs[__.id_of sensor]
      .setSource (callback) =>
        TS.loadFeed sensor.properties.env_channel
        , ((d) -> callback TS.toNv d)
        , @ts_params
    @comf_dataMgrs[__.id_of sensor]
      .setSource (callback) =>
        TS.loadFeed sensor.properties.comf_channel
        , ((d) -> callback TS.toNv d)
        , __.omit_keys TS.AGGREGATION_PARAMS, @ts_params # aggregation not necessary

  _bind_dataMgr_to_sensor: (sensor) ->
    if !@env_dataMgrs[__.id_of sensor]
      @env_dataMgrs[__.id_of sensor] = new DataMgr
      @env_dataMgrs[__.id_of sensor].addSubscriber (data) =>
          @_bind_env_data_to_sensor sensor, data
          do @_draw_node_status

    if !@comf_dataMgrs[__.id_of sensor]
      @comf_dataMgrs[__.id_of sensor] = new DataMgr
      @comf_dataMgrs[__.id_of sensor].addSubscriber (data) =>
          @_bind_comf_data_to_sensor sensor, data
          do @_draw_node_status

    @_update_source sensor
    do @env_dataMgrs[__.id_of sensor].begin
    do @comf_dataMgrs[__.id_of sensor].begin

  _bind_env_data_to_sensor: (sensor, nvData) ->
    sensor.properties.temperatures = (d.y for d in nvData?[0].values)
    sensor.properties.humidities = (d.y for d in nvData?[1].values)
    sensor.properties.th_times = (d.x for d in nvData?[0].values)
    sensor.properties.env_nvData = nvData

  _bind_comf_data_to_sensor: (sensor, nvData) ->
    sensor.properties.comfortabilities = (d.y for d in nvData?[0].values)
    sensor.properties.comf_times = (d.x for d in nvData?[0].values)
    sensor.properties.comf_nvData = nvData

  _draw_node_status: ->
    # svg:g container for each sensor
    @sensor_sel = @parent.selectAll '.sensor'
      .data @sensors
    @sensor_enter = @sensor_sel.enter()
      .append 'g'
      .attr 'class', 'sensor'
    @sensor_sel
      .attr "transform", (d) =>
        "translate(#{(@floors.indexOf __.floor_of d) * @node_h_spacing},
        #{floor_title_height + @node_v_spacing *
        (@sensors_by_floor[@floors.indexOf __.floor_of d].indexOf d)})"

    # Textual current data for each sensor
    @sensor_enter.append 'text'
      .attr 'class', 'status'
      #.attr 'dy', '1em'
    @sensor_sel.select '.status'
      .each (d) ->
        av_temp = do d.properties.temperatures.last
        text = "[#{__.id_of d}]: #{d.properties.description}\n
        #{(do d.properties.temperatures.last)?.toFixed 2}ºC,
        #{(do d.properties.humidities.last)?.toFixed 2}% humidity,
        #{__.comfort_rating_to_desc (
          do (d.properties.comfortabilities.filter (x) -> x).average)}"
        lines = text.split /\n/
        tspan = (d3.select @).selectAll 'tspan'
          .data lines
        tspan.enter()
          .append 'tspan'
          .attr 'x', 0
          .attr 'dy', '1.1em'
        tspan.text (d) -> d
    @text_height = __.svg_px_height @sensor_sel.select '.status'

    # Temperature history plot
    @_plot_mini_chart 'temp_history', @temp_charts, 0, 'Temperature'

    # Humidity history plot
    @_plot_mini_chart 'hum_history', @hum_charts, 1, 'Humidity'

  _plot_mini_chart: (chart_class, chart_dict, index, title='') ->
    translation = "translate(#{index * @node_width / 2},#{@text_height+20})"
    @sensor_enter.append 'text'
      .attr 'class', 'mini_chart_title'
      .attr 'id', chart_class + '_title'
      .text title
      .attr 'dy', -8
    @sensor_sel.select '#' + chart_class + '_title'
      .attr 'x', @node_width / 4
      .attr "transform", translation
    @sensor_enter.append 'g'
      .attr 'class', chart_class
      .each (d) ->
        chart = new LineChart d3.select @
        chart.chart
          .margin {left: 35, top: 5, bottom: 0, right: 35}
          .showLegend? false
          .useInteractiveGuideline? false
        chart_dict[__.id_of d] = chart
    @sensor_sel.select '.' + chart_class
      .attr "transform", translation
      .each (d) =>
        chart = chart_dict[__.id_of d]
        chart.chart
          .width @node_width / 2
          .height @node_height - @text_height - 5
        chart.updateChart [d.properties.env_nvData?[index]]


module.exports = StatusDrawer
