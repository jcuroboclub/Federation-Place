# Created by AshGillman, 19/5/14
TS = require './ThingSpeak'
D3P = require './D3Plotter.coffee'
LineChart = require('./NvWrapper').LineChart
DataMgr = require('./DataManager').DataManager
FloorPlan = require('./FloorPlan')

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

## Test

square_room =
  type: "Feature"
  geometry:
    type: "Polygon"
    coordinates: [[
        #[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.5], [0.0, 0.0]
        [0.0, 0.0], [0.0, 1.0], [1.0, 1.0], [0.5, 0.0], [0.0, 0.0]
      ]]
    properties:
      name: "Square Room"

l_shaped_room =
  type: "Feature"
  geometry:
    type: "Polygon"
    coordinates: [[
        [1.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 2.0], [0.0, 1.0], [1.0, 1.0],
        [1.0, 0.0]
      ]]
    properties:
      name: "Square Room"

floor_with_square_room =
  type: "FeatureCollection"
  features: [square_room]

floor_with_two_rooms =
  type: "FeatureCollection"
  features: [square_room, l_shaped_room]

width = 256
height = 256
svg = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height)
plan = new FloorPlan.FloorPlan(svg)
plan.plotMap(floor_with_two_rooms)
