# Created by AshGillman, 19/5/14
TS = require './ThingSpeak'
D3P = require './D3Plotter.coffee'
LineChart = require('./NvWrapper').LineChart
DataMgr = require('./DataManager').DataManager

channelid = 20466 # 33970
anchorId = 'vis'
#mainAnchor = D3P.appendAnchor('body', anchorId)

addDebug = (fn) -> (d...) ->
  console.log fn, d
  fn d...

App =
  start: ->
    mainChart = new LineChart('#' + anchorId + ' svg')
    dataMgr = new DataMgr
    dataMgr.setSource (callback) ->
        TS.loadFeed channelid, (d) ->
          callback(TS.toNv(d))
      .addSubscriber mainChart.updateChart
      .begin()

module.exports = App
