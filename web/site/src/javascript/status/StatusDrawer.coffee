# Created by AshGillman, 12/07/15
__ = require '../helpers'
TS = require '../thingspeak'
DataMgr = require('../DataManager').DataManager
LineChart = require('../NvWrapper').LineChart


# constants/magic numbers
floor_title_height = 30 # height of the floor title
node_w_h_ratio = 2 # desired aspect ratio (width:height) of each node
node_h_margin = 20 # horizontal margin between nodes
node_v_margin = 40 # vertical margin between nodes
node_internal_margin = 10 # margin inside node between elements
comfort_plot_height = 2 * __.svg_px_size (d3.select 'body'), 'font-size'
n_samples = 1000 # no. samples to download from ThingSpeak


emotify_comf = (comf) ->
  return '😶' if not comf
  return '😫' if 1   <= comf <  1.3
  return '😒' if 1.3 <  comf <  1.7
  return '😐' if 1.7 <  comf <  2.3
  return '😉' if 2.3 <  comf <  2.7
  return '😄' if 2.7 <  comf <= 3
  return '😡'
comfort_rating_to_desc = (comf) ->
  text = do ->
    return 'unrated'            if not comf
    return 'very uncomfortable' if 1   <= comf <  1.3
    return 'uncomfortable'      if 1.3 <  comf <  1.7
    return 'indecisive'         if 1.7 <  comf <  2.3
    return 'comfortable'        if 2.3 <  comf <  2.7
    return 'very comfortable'   if 2.7 <  comf <= 3
    return '<error>'
  return text + ' ' + emotify_comf comf

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
        #{comfort_rating_to_desc (
          do (d.properties.comfortabilities.filter (x) -> x).average)}"
        lines = text.split /\n/
        tspan = (d3.select @).selectAll 'tspan'
          .data lines
        tspan.enter()
          .append 'tspan'
          .attr 'x', 0
          .attr 'dy', '1.1em'
        tspan.text (d) -> d
    @text_height = (__.svg_px_height @sensor_sel.select '.status') +
        __.svg_px_size (@sensor_sel.select '.status'), 'font-size'

    # Temperature history plot
    @_plot_mini_chart 'temp_history', @temp_charts, 0, 'Temperature'

    # Humidity history plot
    @_plot_mini_chart 'hum_history', @hum_charts, 1, 'Humidity'

    do @_plot_comf_hist

  _plot_mini_chart: (chart_class, chart_dict, index, title='') ->
    translation = "translate(#{index * @node_width / 2},
    #{@text_height + node_internal_margin})"
    width = @node_width / 2
    height = @node_height - @text_height - comfort_plot_height -
        2 * node_internal_margin
    @sensor_enter.append 'text'
      .attr 'class', 'mini_chart_title'
      .attr 'id', chart_class + '_title'
      .text title
      .attr 'dy', -8
    @sensor_sel.select '#' + chart_class + '_title'
      .attr 'x', width / 2
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
      .each (d) ->
        chart = chart_dict[__.id_of d]
        chart.chart
          .width width
          .height height
        chart.updateChart [d.properties.env_nvData?[index]]

  _plot_comf_hist: ->
    [width, height] = [@node_width, comfort_plot_height]
    y = @node_height - comfort_plot_height
    #data = @sensor.properties.comf_nvData.values
    [get_x, get_y] = [((d) -> d.x), ((d) -> d.y)]
    history_limit = new Date
    history_limit.setDate history_limit.getDate() - @ts_params.days
    x = d3.time.scale()
      .range [0, width]
      .domain [history_limit, new Date]
    xAxis = d3.svg.axis()
      .scale x
      .orient 'bottom'
    do =>
      domain_in_days = @ts_params.days
      format = do ->
        return '%I:%M %p' if domain_in_days < 2
        return '%a'       if domain_in_days < 8
        return '%e %b'
      ticks = do ->
        return 4 if domain_in_days < 2
        return 8 if domain_in_days < 8
        return 6
      xAxis
        .tickFormat (d) -> (d3.time.format format) new Date d
        .ticks ticks

    plot_class = 'comf_history_chart'
    @sensor_enter.append 'g'
        .attr 'class', plot_class + ' nvd3'
      .append 'g'
        .attr 'class', 'x axis'
    @sensor_sel.select '.' + plot_class + '.nvd3'
      .attr 'transform', "translate(0, #{y})"
    @sensor_sel.select '.x.axis'
      .call xAxis
      .attr 'transform', "translate(0, #{height})"

    @sensor_sel.selectAll '.' + plot_class
      .each (d) ->
        d.properties.comf_nvData ?= [{}]
        d.properties.comf_nvData?[0].values ?= []
        plot_sel = d3.select @
          .selectAll '.point'
          .data d.properties.comf_nvData[0].values
        plot_sel.enter()
          .append 'text'
          .attr 'class', 'point'
          #.style 'font-size', '16'
          .style 'text-anchor', 'middle'
        plot_sel
          .attr 'x', (d) -> x d.x
          .attr 'y', (d)-> comfort_plot_height - d.y / 3 * node_internal_margin
          .text (d) -> emotify_comf d.y
        plot_sel.exit().remove()

module.exports = StatusDrawer
