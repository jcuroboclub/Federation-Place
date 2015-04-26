# Created by AshGillman, 26/4/15

exports.Plotter = class Plotter
  constructor: ->
    @plotfuncs = {}

  addPlot: (type, func) ->
    @plotfuncs[type] = func
    return @

  plot: (type, data) ->
    @plotfuncs[type](data)

exports.PlotManager = class PlotManager
  constructor: (@main, @focus) ->

  update: (type, data) ->
    @main.plot(type, data) if type of @main.plotfuncs
    @focus.plot(type, data) if type of @focus.plotfuncs