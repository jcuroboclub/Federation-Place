_ = require 'underscore'
$ = require 'jquery'
d3 = require 'd3'
require 'nvd3/build/nv.d3.js'

channelid = 33970
spineData = []
THINGSPEAK_FIELDS = _.map(_.range(1, 9), (x) ->
  'field' + x
)

# converts date format from JSON
getChartDate = (d) ->
  d3.time.format.utc('%Y-%m-%dT%H:%M:%SZ').parse d

# Date formatting
formatHours = (d) ->
  d3.time.format('%H:%M') new Date(d)

lineChart = ->
  console.log(nv)
  console.log(nv.models)
  chart = nv.models.lineWithFocusChart()
  #.useInteractiveGuideline(true)
  chart.xAxis.axisLabel('Time').tickFormat formatHours
  chart.x2Axis.tickFormat formatHours
  chart.yAxis.axisLabel('Temp (C)').tickFormat d3.format('.1f')
  chart.yAxis.tickFormat d3.format('.1f')
  #chart.useInteractiveGuideline(true);
  nv.utils.windowResize chart.update
  chart

loadGraph = (chart, data) ->
  d3.select('#nvd3 svg').datum(data).call chart
  chart

updatePlot = (chart) ->
  $.getJSON 'http://api.thingspeak.com/channels/' + channelid + '/feed.json?', (data) ->
    # [{"created_at":"YYYY-MM-DDTHH:mm:ssZ","entry_id":X,"field1":"X","field2":"X",...,"field8":"X"}]
    # to
    # [{"key": "field1","values": [{"x": "YYYY-MM-DDTHH:mm:ssZ", "y": X}, ... ]},
    #  {"key": "field2","values": [{"x": "YYYY-MM-DDTHH:mm:ssZ", "y": X}, ... ]}, ...
    #  {"key": "field8","values": [{"x": "YYYY-MM-DDTHH:mm:ssZ", "y": X}, ... ]}]
    spineData = _.map(THINGSPEAK_FIELDS, (f) ->
      {
      'key': data.channel[f]
      'values': _.map(data.feeds, (d) ->
        {
        'x': getChartDate(d.created_at)
        'y': d[f]
        }
      )
      }
    )
    loadGraph chart, spineData
    console.log 'plot'
    return
  return

#$(document).ready ->
#  updatePlot()
#  # check for new updates
#  setInterval 'updatePlot()', 15000
#  return

App =
  start: ->
    console.log "app started!"
    spineChart = lineChart()
    updatePlot(spineChart)
    setInterval (do (spineChart) -> -> updatePlot(spineChart)), 15000

module.exports = App