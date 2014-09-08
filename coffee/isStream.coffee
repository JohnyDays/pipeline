# Type checking for nodejs streams

responds_to = require 'type-checking'

isEventEmitter = (obj)->
  responds_to(obj, ['on'])

isReadable     = (obj) ->
  responds_to(obj, ['read'])  or responds_to(obj, ['_read'])  or responds_to(obj, ['readable'])

isWritable     = (obj) ->
  responds_to(obj, ['write']) or responds_to(obj, ['_write']) or responds_to(obj, ['writable']) 

isDuplex       = (obj) ->
  isReadable(obj) and isWritable(obj)

isTransform    = (obj) ->
  responds_to(obj, ['_transform'])

isStream       = (obj) ->
  isEventEmitter(obj) and (isReadable(obj) or isWritable(obj) or isTransform(obj)) 

module.exports            = isStream
module.exports.isReadable = isReadable
module.exports.isWritable = isWritable
module.exports.isDuplex   = isDuplex
