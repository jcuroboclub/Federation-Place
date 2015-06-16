# Created by AshGillman, 25/4/15

PM = require '../PlotManager'

fakeData = (n) -> [key: "fake", values: [y: n, x: new Date Date.UTC(n)]]
fakePlot = plot: ((data) -> fakePlot.data = data), data: undefined

describe 'Plotter', ->
  it 'calls the appropriate plot function', ->
    p = new PM.Plotter()
    p.addPlot("type", fakePlot.plot).plot("type", "data")
    fakePlot.data.should.equal "data"

describe 'PlotManager', ->
  before 'Set up Plotter', ->
    @fakeMain = new PM.Plotter()
    @fakeFocus = new PM.Plotter()
    @fakeMain.addPlot("dataType", fakePlot.plot)
    @pm = new PM.PlotManager(@fakeMain, @fakeFocus)

  xit 'manages plots on the page', ->
    # TODO
  it 'updates the plot', ->
    @pm.update("dataType", fakeData(1))
    fakePlot.data.should.deep.equal fakeData(1)