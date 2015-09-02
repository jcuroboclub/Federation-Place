# Created by AshGillman, 05/08/12
__           = require '../helpers'
ScatterChart = require('../NvWrapper').ScatterChart
DrawerBase   = require '../DrawerBase'

ScatterDrawer = class ScatterDrawer extends DrawerBase
  constructor: (@parent, sensor_metadata, @ts_params) ->
    super(@parent, sensor_metadata, @ts_params)

    size = Math.min (__.svg_px_width @parent), (__.svg_px_height @parent)
    @parent.style 'height', size
    @parent.style 'width', size

    @chart ?= new ScatterChart @parent
    @chart.chart.xAxis.axisLabel 'Temperature (℃)'
    @chart.chart.yAxis.axisLabel 'Humidity (%)'
    @chart.chart.margin {left: 70, right: 20, top: 20, bottom: 70}

    do do @redraw

  # NOTE: returns a closure
  redraw: ->
    context = @
    return ->
      for sensor in context.sensors
        context._bind_dataMgr_to_sensor sensor

  _draw_node_status: ->

    plot_data =
      [{
        key: 'Uncomfortable'
        values: []
      },
      {
        key: 'Indecisive'
        values: []
      },
      {
        key: 'Comfortable'
        values: []
      }]

    for {properties} in @sensors
      if properties.comf_times.length > 0 and properties.th_times.length > 0
        for comf, i in properties.comfortabilities
          time = properties.comf_times[i]
          th_index = properties.th_times.findIndex (d) -> d > time
          if th_index >= 0
            plot_data[comf-1].values.push {
              x: properties.temperatures[th_index]
              y: properties.humidities[th_index]
              }
    do plot_data.reverse
    #console.log plot_data.map((x) -> x.values.length)
    @chart.updateChart plot_data

module.exports = ScatterDrawer
