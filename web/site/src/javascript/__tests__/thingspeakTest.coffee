ts = require '../ThingSpeak'

# This is the format of data that we get from ThingSpeak
tsData =
  channel:
    id:33970
    name:"Spine Lower"
    description:"Lower 8 Temp sensors of the spine."
    field1:"T1"
    field2:"T2"
    field3:"T3"
    field4:"T4"
    field5:"T5"
    field6:"T6"
    field7:"T7"
    field8:"T8"
    created_at:"2015-04-14T13:59:41Z"
    updated_at:"2015-04-22T23:01:41Z"
    last_entry_id:2388
  feeds:[
    {
      created_at: "2015-04-22T23:01:25Z"
      entry_id: 2387
      field1: "28.5355339059"
      field2: "25.0"
      field3: "21.4644660941"
      field4: "20.0"
      field5: "21.4644660941"
      field6: "25.0"
      field7: "28.5355339059"
      field8: "30.0"
    }, {
      created_at:"2015-04-22T23:01:41Z"
      entry_id:2388
      field1:"25.0"
      field2:"21.4644660941"
      field3:"20.0"
      field4:"21.4644660941"
      field5:"25.0"
      field6:"28.5355339059"
      field7:"30.0"
      field8:"28.5355339059"
    }]

# The data format I will likely be using is that based on the NVD3 library.
describe 'thingspeak toNv', ->
  it 'should be in the correct format', ->
    ts.toNv(tsData)[0].key.should.be.a 'string'
    ts.toNv(tsData)[7].key.should.be.a 'string'
    ts.toNv(tsData)[0].values[0].x.should.be.a 'Date'
    ts.toNv(tsData)[0].values[1].x.should.be.a 'Date'
    ts.toNv(tsData)[0].values[0].y.should.be.a 'Number'
    ts.toNv(tsData)[0].values[1].y.should.be.a 'Number'
  it 'should have the correct Values', ->
    ts.toNv(tsData)[0].key.should.equal tsData.channel.field1
    ts.toNv(tsData)[0].values[0].x.toString().should.equal \
      (new Date Date.UTC(2015, 3, 22, 23, 1, 25, 0)).toString()
    ts.toNv(tsData)[0].values[0].y.should.equal 28.5355339059

# ThingSpeak has a simple http API to request data in JSON format.
describe 'thingspeak loadFeed', ->
  before 'Load the Channel 3 thingspeak data', (done) =>
    ts.loadFeed 3, (data) =>
      @channel3Data = data
      do done
    , 1

  it 'should return something', ->
    (ts.loadFeed 3).should.be.a 'object'
  it 'should return in format consistent w/ api docs', =>
    @channel3Data.should.have.property 'channel'
    @channel3Data.feeds.should.be.a 'array'
  it 'should return no more than n results', =>
    @channel3Data.feeds.should.have.length.most 1