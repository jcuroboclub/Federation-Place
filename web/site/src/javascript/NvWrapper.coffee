d3 = require 'd3'
require 'nvd3/build/nv.d3.js' # as nv

class ChartBase
  constructor: (@target) ->
    @oldlast = 0
    @chart = do @_makeChart

  _makeChart: ->

  # Override this
  updateChart: (data) ->
    @_draw(data)

  _draw: (data) ->
    (if typeof @target is 'string' then d3.select @target else @target)
      .datum data
      .call @chart

exports.LineChart = class LineChart extends ChartBase
  _makeChart: ->
    chart = nv.models.lineChart()
    chart.useInteractiveGuideline? true
    chart.xAxis
      .axisLabel ''
      .tickFormat (d) ->
        (d3.time.format '%I:%M %p') new Date d
    chart.yAxis
      .axisLabel ''
      .tickFormat d3.format '.2f'
    # chart.color (d) -> getColor d.key
    nv.utils.windowResize(chart.update)
    return chart

  updateChart: (data) ->
    if !data?[0]
      return
    domain_in_days = do (oneDay = 24*60*60*1000) ->
      Math.abs (data[0].values.last()?.x - data[0].values?[0]?.x) / oneDay
    format = do ->
      return '%I:%M %p' if domain_in_days < 2
      return '%a'       if domain_in_days < 8
      return '%e %b'
    @chart.xAxis.tickFormat (d) -> (d3.time.format format) new Date d
    #@chart.yAxis.axisLabel data[0].key
    @_draw(data)

exports.ScatterChart = class ScatterChart extends ChartBase
  _makeChart: ->
    chart = nv.models.scatterChart()
    chart
      .useInteractiveGuideline? true
      .color d3.scale.category10().range()
    nv.utils.windowResize(chart.update)
    return chart

  updateChart: (data) ->
    if !data?[0]
      return
    @_draw(data)
