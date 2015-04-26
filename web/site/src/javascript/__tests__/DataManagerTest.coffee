# Created by AshGillman, 24/04/15

DM = require '../DataManager'

fakeData = (n) -> [key: "fake", values: [y: n, x: new Date Date.UTC(n)]]

describe 'DataManager', ->
  @intendedcount = 10
  @count = 0
  @interval = 10
  @first=0
  @fakeSource = (done) => (callback) =>
    @count += 1
    @first = do Date.now if @count <= 1
    callback(fakeData(@count))
    if @count >= 10
      @diff = do Date.now - @first
      do done
      do @dm.end
  @rxcount = 0
  @rxdata = 0
  @fakeSubscriber = (data) =>
    @rxcount += 1
    @rxdata = data

  before 'setup fake DataManager source', (done) =>
    @dm = new DM.DataManager()
    @dm.setSource @fakeSource(done)
      .setTime @interval
      .addSubscriber @fakeSubscriber
    do @dm.begin

  it 'updates at a regular interval', =>
    @diff.should.be.above @interval * @count * 0.8
    @diff.should.be.below @interval * @count * 1.2 + 100
  it 'updates data from the source function', =>
    @dm.data[0].key.should.equal fakeData(0)[0].key
    @rxdata[0].key.should.equal fakeData(0)[0].key
  it 'notifies its subscribers', =>
    @rxcount.should.equal @count

  describe 'end()', =>
    it 'stops the updating', =>
      @count.should.equal @intendedcount