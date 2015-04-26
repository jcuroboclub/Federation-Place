# Created by AshGillman, 24/04/15

DM = require '../DataManager'

fakeData = [key: "fake", values: [x: 0, y: new Date Date.UTC(0)]]

describe 'DataManager', ->
  @intendedcount = 10
  before 'setup fake DataManager source', (done) =>
    @count = 0
    @interval = 10
    @first=0
    update = =>
      @count += 1
      @first = do Date.now if @count <= 1
      if @count >= 10
        @diff = do Date.now - @first
        do done
        do @dm.end
      return fakeData
    @dm = new DM.DataManager(update, @interval)
    @rxcount = 0
    @rxdata = 0
    @dm.addSubscriber (data) =>
      @rxcount += 1
      @rxdata = data
    do @dm.begin

  it 'updates at a regular interval', =>
    @diff.should.be.above @interval * @count * 0.8
    @diff.should.be.below @interval * @count * 1.2 + 100
  it 'updates from the source function', =>
    @dm.data[0].key.should.equal fakeData[0].key
    @rxdata[0].key.should.equal fakeData[0].key
  it 'notifies its subscribers', =>
    @rxcount.should.equal @count

  describe 'end()', =>
    it 'stops the updating', =>
      @count.should.equal @intendedcount