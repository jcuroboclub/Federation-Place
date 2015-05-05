d3 = require 'd3'
require 'nvd3/build/nv.d3.js' # as nv

exports.LineChart = class LineChart
  constructor: (@target) ->
    @oldlast = 0
    @chart = do @_makeChart

  _makeChart: ->
    chart = nv.models.lineChart()
    chart.useInteractiveGuideline?(true)
    chart.xAxis.axisLabel('Time').tickFormat (d) ->
      d3.time.format('%H:%M') new Date(d)
    chart.yAxis.axisLabel('Temp (C)').tickFormat d3.format('.1f')
    chart.color (d) -> getColor d.key
    nv.utils.windowResize(chart.update)
    return chart

  updateChart: (data) =>
    field1 = data[0]
    last = field1.values[field1.values.length-1]
    if last isnt @oldlast # if updated
      @oldlast = last
      console.log @target
      d3.select(@target).datum(data).call @chart
