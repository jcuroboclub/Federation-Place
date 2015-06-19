# Created by AshGillman, 17/06/15

FloorPlan = require '../FloorPlan'
$ = require 'jquery'
d3 = require 'd3'

square_room =
  type: "Feature"
  geometry:
    type: "Polygon"
    coordinates: [[
        [0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]
      ]]
    properties:
      name: "Square Room"

big_square_room =
  type: "Feature"
  geometry:
    type: "Polygon"
    coordinates: [[
        [1.0, 1.0], [11.0, 1.0], [11.0, 11.0], [1.0, 11.0], [1.0, 1.0]
      ]]
    properties:
      name: "Square Room"

rectangle_room =
  type: "Feature"
  geometry:
    type: "Polygon"
    coordinates: [[
        [0.0, 0.0], [3.0, 0.0], [3.0, 1.0], [0.0, 1.0], [0.0, 0.0]
      ]]
    properties:
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
      name: "Square Room"

floor =
  type: "FeatureCollection"
  features: []

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

describe 'FloorPlan', ->
  afterEach ->
    do (svg.selectAll '*').remove
    do (svg2.selectAll '*').remove
    floor.features = {}

  it 'can represent a single room as an svg element of class room', ->
    expect(do (svg.selectAll '*').empty).to.be.true

    plan = new FloorPlan.FloorPlan svg
    floor.features = [square_room]
    plan.plotMap floor

    expect(do (svg.selectAll '.fp_room').size).to.equal 1

  it 'can represent a two rooms as two svg elements of class room', ->
    expect(do (svg.selectAll '.fp_room').empty).to.be.true

    plan = new FloorPlan.FloorPlan svg
    floor.features = [square_room, l_shaped_room]
    plan.plotMap floor

    expect(do (svg.selectAll '.fp_room').size).to.equal 2

  it 'represents different rooms in different colours', ->
    plan = new FloorPlan.FloorPlan svg
    floor.features = [square_room, l_shaped_room]
    plan.plotMap floor

    fillCols = []
    (svg.selectAll '.fp_room').each ->
      fillCols.push (d3.select @).style 'fill'

    fillCols[0].should.not.equal fillCols[1]

  it 'automatically scales figures', ->
    plan = new FloorPlan.FloorPlan svg
    floor.features = [square_room]
    plan.plotMap floor
    plan2 = new FloorPlan.FloorPlan svg2
    floor2 = $.extend({}, floor)
    floor2.features = [big_square_room]
    plan2.plotMap floor2

    ((svg.selectAll '.fp_room').attr 'points')
      .should.equal (svg2.selectAll '.fp_room').attr 'points'

  it "doesn't stretch figures", ->
    plan = new FloorPlan.FloorPlan svg
    floor.features = [square_room]
    plan.plotMap floor
    plan2 = new FloorPlan.FloorPlan svg2
    floor2 = $.extend({}, floor)
    floor2.features = [rectangle_room]
    plan2.plotMap floor2

    ((svg.selectAll '.fp_room').attr 'points')
      .should.not.equal (svg2.selectAll '.fp_room').attr 'points'
