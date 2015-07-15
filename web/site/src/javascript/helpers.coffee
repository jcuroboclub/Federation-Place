# Created by AshGillman 15/7/15


# Array Prototype updates

do -> Array::last ?= -> @[@length - 1]
# https://coffeescript-cookbook.github.io/chapters/arrays/removing-duplicate-elements-from-arrays
do -> Array::unique ?= ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output
do -> Array::filter ?= (callback) ->
  element for element in this when callback element
do -> Array::sum ?= -> @reduce ((a, b) -> a + b), 0
do -> Array::average ?= -> if @length then do @sum / @length else 0


# Function Prototype updates

# http://unscriptable.com/2009/03/20/debouncing-javascript-methods/
do -> Function::debounce ?= (threshold=100, execAsap=true) ->
  fn = @
  timeout = undefined
  debounced = ->
    delayed = ->
      fn.apply obj, args  unless execAsap
      timeout = null
      return
    obj = @
    args = arguments
    if timeout
      clearTimeout timeout
    else func.apply obj, args if execAsap
    timeout = setTimeout(delayed, threshold)
    return


# Helper functions

exports.floor_of = (sensor) -> sensor.geometry.coordinates[2]
exports.id_of = (sensor) -> sensor.properties.id
exports.svg_px_width = (el) -> +(el.style 'width')[0..-3]
exports.svg_px_height = (el) -> +(el.style 'height')[0..-3]
exports.comfort_rating_to_desc = (comf) ->
  return 'unrated'            if not comf
  return 'very uncomfortable' if 1   <= comf <  1.3
  return 'uncomfortable'      if 1.3 <  comf <  1.7
  return 'indecisive'         if 1.7 <  comf <  2.3
  return 'comfortable'        if 2.3 <  comf <  2.7
  return 'very comfortable'   if 2.7 <  comf <= 3
  return '<error>'
exports.omit_keys = (keys, obj) ->
  new_obj = {}
  new_obj[k] = v for k, v of obj when k not in keys
  return new_obj
# inline debugger
exports.addDebug = (fn) -> (d...) ->
  console.log fn, d
  fn d...
# https://coffeescript-cookbook.github.io/chapters/classes_and_objects/cloning
clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj

  if obj instanceof Date
    return new Date(obj.getTime())

  if obj instanceof RegExp
    flags = ''
    flags += 'g' if obj.global?
    flags += 'i' if obj.ignoreCase?
    flags += 'm' if obj.multiline?
    flags += 'y' if obj.sticky?
    return new RegExp(obj.source, flags)

  newInstance = new obj.constructor()

  for key of obj
    newInstance[key] = clone obj[key]

  return newInstance
exports.clone = clone
