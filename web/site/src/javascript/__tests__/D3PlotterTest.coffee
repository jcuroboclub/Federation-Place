# Created by AshGillman, 26/04/15

D3P = require '../D3Plotter'
$ = require 'jquery'

fakeData = (n) -> [key: 'fake', values: [y: n, x: new Date Date.UTC(n)]]

describe 'D3Plotter functions', ->
  describe 'redraw', ->
    it 'should pass a selection to a worker function', ->
      D3P.redraw 'body', (selection) ->
        selection[0][0].should.equal document.body
      , fakeData 0
    it 'should associated data with the selection', ->
      D3P.redraw 'body', (selection) ->
        selection.datum().should.deep.equal fakeData 1
      , fakeData 1

  describe 'appendAnchor', ->
    it 'should append a p #id element with an svg element', ->
      p = D3P.appendAnchor 'body', 'id'
      p[0][0].should.equal $('body p')[0]
      p[0][0].should.equal $('#id')[0]
      should.exist $('#id svg')[0]
      should.not.exist $('#ix svg')[0]
      should.not.exist $('#id p')[0]