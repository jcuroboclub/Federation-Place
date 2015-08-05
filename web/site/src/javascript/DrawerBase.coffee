# Created by AshGillman, 05/08/2015
# A Drawer is a class that physically generates the desired plots.
__        = require './helpers'
TS        = require './thingspeak'
DataMgr   = require('./DataManager').DataManager


# constants/magic numbers
floor_title_height   = 30   # height of the floor title
node_w_h_ratio       = 2    # aspect ratio (width:height) of each node
node_h_margin        = 20   # horizontal margin between nodes
node_v_margin        = 40   # vertical margin between nodes
node_internal_margin = 10   # margin inside node between elements
comfort_plot_height  = 2 * __.svg_px_size (d3.select 'body')
                           , 'font-size'
n_samples            = 1000 # no. samples to download from ThingSpeak


DrawerBase = class StatusDrawer
  constructor: (@parent, sensor_metadata, @ts_params) ->
    @sensors = sensor_metadata.features

    @temp_charts   = {}
    @hum_charts    = {}
    @env_dataMgrs  = {}
    @comf_dataMgrs = {}

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
        , __.omit_keys TS.AGGREGATION_PARAMS
        , @ts_params # aggregation not necessary

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
    sensor.properties.humidities   = (d.y for d in nvData?[1].values)
    sensor.properties.th_times     = (d.x for d in nvData?[0].values)
    sensor.properties.env_nvData   = nvData

  _bind_comf_data_to_sensor: (sensor, nvData) ->
    sensor.properties.comfortabilities =
      (d.y for d in nvData?[0].values)
    sensor.properties.comf_times =
      (d.x for d in nvData?[0].values)
    sensor.properties.comf_nvData = nvData

module.exports = DrawerBase
