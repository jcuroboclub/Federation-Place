# Created by AshGillman 23/4/15

exports.Datamanager = class DataManager
  constructor: (@source, @interval) ->
    @data = [key: "", values: [x: 0, y: new Date]] # nvd3 format
    @_subscribers = []

  # addSubscribers. Subscriber are expected to be callables with single data
  # argument
  addSubscriber: (subscriber) ->
    @_subscribers.push(subscriber)

  _notifyAll: ->
    subscriber(@data) for subscriber in @_subscribers

  _update: =>
    newdata = do @source
    [..., newlast] = newdata[0].values
    [..., oldlast] = @data[0].values
    @data = newdata if newlast isnt oldlast
    do @_notifyAll

  # source: callable, returns data in nvd3 format
  begin: ->
    #console.log(@data)
    @pid = setInterval @_update, @interval

  end: ->
    clearInterval(@pid)