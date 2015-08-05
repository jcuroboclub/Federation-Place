# Created by AshGillman, 05/08/12
__         = require '../helpers'
#LineChart = require('../NvWrapper').ScatterChart
DrawerBase = require '../DrawerBase'

ScatterDrawer = class ScatterDrawer extends DrawerBase
  constructor: (@parent, sensor_metadata, @ts_params) ->
    super(@parent, sensor_metadata, @ts_params)
    do do @redraw

  # NOTE: returns a closure
  redraw: ->
    -> console.log 'draw'

module.exports = ScatterDrawer
