# Created by AshGillman, 19/5/14
TS = require './ThingSpeak'
D3P = require './D3Plotter.coffee'
LineChart = require('./NvWrapper').LineChart
DataMgr = require('./DataManager').DataManager

channelid = 33970
mainAnchor = D3P.appendAnchor('body', 'vis')

App =
  start: ->
    mainChart = new LineChart(mainAnchor)
    dataMgr = new DataMgr
    listener = (d) ->
      console.log d
      mainChart.updateChart d
    dataMgr.setSource((callback) -> TS.loadFeed channelid, callback)
      .addSubscriber listener
      .begin()

module.exports = App
