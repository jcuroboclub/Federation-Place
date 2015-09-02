# Created by AshGillman 15/7/15


# Array Prototype updates

do -> Array::last ?= -> @[@length - 1]
# https://coffeescript-cookbook.github.io/chapters/arrays/removing-duplicate-elements-from-arrays
do -> Array::unique ?= ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output
do -> Array::filter ?= (predicate) ->
  element for element in this when predicate element
do -> Array::sum ?= -> @reduce ((a, b) -> a + b), 0
do -> Array::average ?= -> if @length then do @sum / @length else 0
do -> Array::findIndex ?= (predicate) ->
  return i for value, i in @ when predicate value
  return -1


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

svg_px_size_by_style = (el, attr) ->
  size = +(el.style attr)[0..-3]
  if size then size else 0
svg_px_size_by_bbox = (el, attr) -> el.node().getBBox()[attr]
exports.svg_px_size = svg_px_size_by_style
exports.svg_px_width = (el) ->
  size_by_style = svg_px_size_by_style el, 'width'
  if size_by_style then size_by_style else svg_px_size_by_bbox el, 'width'
exports.svg_px_height = (el) ->
  size_by_style = svg_px_size_by_style el, 'height'
  if size_by_style then size_by_style else svg_px_size_by_bbox el, 'height'

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
