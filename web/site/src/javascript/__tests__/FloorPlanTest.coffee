# Created by AshGillman, 17/06/15

FloorPlan = require '../FloorPlan'
$ = require 'jquery'
d3 = require 'd3'

# Floor Plan Test Definitions

unit_square_room =
  type: "Feature"
  geometry:
    type: "Polygon"
    coordinates: [[
        [0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]
      ]]
  properties:
    type: 'room'
    name: 'Square Room'

big_square_room =
  type: "Feature"
  geometry:
    type: "Polygon"
    coordinates: [[
        [1.0, 1.0], [11.0, 1.0], [11.0, 11.0], [1.0, 11.0], [1.0, 1.0]
      ]]
  properties:
    type: 'room'
    name: "Square Room"

rectangle_room =
  type: "Feature"
  geometry:
    type: "Polygon"
    coordinates: [[
        [0.0, 0.0], [3.0, 0.0], [3.0, 1.0], [0.0, 1.0], [0.0, 0.0]
      ]]
  properties:
    type: 'room'
    name: "Square Room"

l_shaped_room =
  type: "Feature"
  geometry:
    type: "Polygon"
    coordinates: [[
        [1.0, 0.0], [2.0, 0.0], [2.0, 2.0], [0.0, 2.0], [0.0, 1.0], [1.0, 1.0],
        [1.0, 0.0]
      ]]
  properties:
    type: 'room'
    name: "Square Room"

floor =
  type: "FeatureCollection"
  features: []

# Sensor test Definitions

sensor1 =
  type: 'Feature'
  geometry:
    type: 'Point'
    coordinates: [0.25, 0.75]
  properties:
    type: 'sensor'
    name: 'Sensor 1'
    temperatures: [25.0, 26.0]
    humidities: [54.5, 54.0]
    th_times: ["2015-06-22T08:38:31+10:00", "2015-06-22T08:38:46+10:00"]

width = 256
height = 256
svg = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("id", "floorPlanTest")
svg2 = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("id", "floorPlanTest")

# helper functions
clone = (obj) ->
  $.extend({}, obj)

deepClone = (obj) ->
  $.extend(true, {}, obj)

describe 'FloorPlan', ->
  afterEach ->
    do (svg.selectAll '*').remove
    do (svg2.selectAll '*').remove
    floor.features = {}


  it "won't crash on a generic FeatureCollection", ->
    featureCollection =
      type: 'FeatureCollection'
      features: [
        type: 'feature'
        geometry: null
      ]

    sensors = new FloorPlan.FloorPlan svg
    sensors.plotMap featureCollection


  describe 'map plotting', ->
    it 'can represent a single room as an svg element of class room', ->
      expect(do (svg.selectAll '*').empty).to.be.true

      plan = new FloorPlan.FloorPlan svg
      floor.features = [unit_square_room]
      plan.plotMap floor

      expect(do (svg.selectAll '.fp_room').size).to.equal 1


    it 'can represent a two rooms as two svg elements of class room', ->
      expect(do (svg.selectAll '.fp_room').empty).to.be.true

      plan = new FloorPlan.FloorPlan svg
      floor.features = [unit_square_room, l_shaped_room]
      plan.plotMap floor

      expect(do (svg.selectAll '.fp_room').size).to.equal 2


    it 'represents different rooms in different colours', ->
      plan = new FloorPlan.FloorPlan svg
      floor.features = [unit_square_room, l_shaped_room]
      plan.plotMap floor

      fillCols = []
      (svg.selectAll '.fp_room').each ->
        fillCols.push (d3.select @).style 'fill'

      fillCols[0].should.not.equal fillCols[1]


    it 'automatically scales figures', ->
      plan = new FloorPlan.FloorPlan svg
      floor.features = [unit_square_room]
      plan.plotMap floor
      plan2 = new FloorPlan.FloorPlan svg2
      floor2 = clone(floor)
      floor2.features = [big_square_room]
      plan2.plotMap floor2

      ((svg.selectAll '.fp_room').attr 'points')
        .should.equal (svg2.selectAll '.fp_room').attr 'points'


    it "doesn't stretch figures", ->
      plan = new FloorPlan.FloorPlan svg
      floor.features = [unit_square_room]
      plan.plotMap floor
      plan2 = new FloorPlan.FloorPlan svg2
      floor2 = clone(floor)
      floor2.features = [rectangle_room]
      plan2.plotMap floor2

      ((svg.selectAll '.fp_room').attr 'points')
        .should.not.equal (svg2.selectAll '.fp_room').attr 'points'


  describe 'sensor plotting', ->
    it 'can plot a representation of each sensor', ->
      expect(do (svg.selectAll '.fp_sensor').size).to.equal 0

      sensors = new FloorPlan.FloorPlan svg
      sensors.plotMap {type: "FeatureCollection", features: [sensor1]}

      expect(do (svg.selectAll '.fp_sensor').size).to.equal 1


    it 'plots senor positions accurately on the existing map', ->
      sensors = new FloorPlan.FloorPlan svg
      sensors.plotMap {
        type: "FeatureCollection"
        features: [unit_square_room, sensor1]
        }

      # point positions
      ((svg.selectAll '.fp_sensor circle').attr 'cx')
        .should.equal "#{Math.round width*0.25}"
      ((svg.selectAll '.fp_sensor circle').attr 'cy')
        .should.equal "#{Math.round width*(1-0.75)}"

      # existing map
      expect(do (svg.selectAll '.fp_room').size).to.equal 1

    it 'shows humidity as the colour of a transparent halo', ->
      sensors = new FloorPlan.FloorPlan svg
      sensor = deepClone sensor1
      sensor.properties.temperatures = [20]
      sensors.plotMap {
        type: "FeatureCollection"
        features: [unit_square_room, sensor]
        }

      ((svg.selectAll '.fp_sensor .fp_humidity').style 'fill-opacity')
        .should.be.below 1
      colour20 = (svg.selectAll '.fp_sensor .fp_humidity').style 'fill'

      sensor.properties.temperatures = [40]
      sensors.plotMap {
        type: "FeatureCollection"
        features: [unit_square_room, sensor]
        }

      ((svg.selectAll '.fp_sensor .fp_humidity').style 'fill')
        .should.not.be colour20
