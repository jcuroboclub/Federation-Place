# Created by AshGillman 23/4/15
default_reload_time = 60*60*1000 # ms

exports.DataManager = class DataManager
  # source: callable, returns data in nvd3 format
  constructor: ->
    @data = [key: "", values: [x: 0, y: new Date]] # nvd3 format
    @_subscribers = []
    @source = (callback) -> callback []
    @interval = default_reload_time

  # Subscriber are expected to be callables with single data argument
  addSubscriber: (subscriber) ->
    @_subscribers.push(subscriber)
    return @

  setTime: (@interval) ->
    return @

  # Source is asynchronous, expects one argument: the callback.
  # Source must call the callback with one argument: the data in nv format.
  setSource: (@source) ->
    return @

  _notifyAll: ->
    subscriber @data for subscriber in @_subscribers

  # Callback on data update: notifies subscribers if data is new.
  on_update: (newdata) =>
    if not newdata[0] or not newdata[0].values
      console.log "Can't interpret data - did you convert to NV?", newdata
      return
    [..., newlast] = newdata[0].values
    [..., oldlast] = @data[0].values
    if newlast isnt oldlast
      @data = newdata
      do @_notifyAll

  begin: ->
    do @update
    @pid = setInterval @update, @interval

  update: =>
    @source @on_update

  end: ->
    clearInterval @pid
