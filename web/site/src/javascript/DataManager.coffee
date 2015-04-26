# Created by AshGillman 23/4/15

exports.DataManager = class DataManager
  # source: callable, returns data in nvd3 format
  constructor: ->
    @data = [key: "", values: [x: 0, y: new Date]] # nvd3 format
    @_subscribers = []
    @source = (callback) -> callback []
    @interval = 15000

  # addSubscribers. Subscriber are expected to be callables with single data
  # argument
  addSubscriber: (subscriber) ->
    @_subscribers.push(subscriber)
    return @

  setTime: (@interval) ->
    return @

  setSource: (@source) ->
    return @

  _notifyAll: ->
    subscriber(@data) for subscriber in @_subscribers

  update: (newdata) =>
    [..., newlast] = newdata[0].values
    [..., oldlast] = @data[0].values
    if newlast isnt oldlast
      @data = newdata
      do @_notifyAll

  begin: ->
    #@source @update
    @pid = setInterval (=> @source @update), @interval

  end: ->
    clearInterval(@pid)