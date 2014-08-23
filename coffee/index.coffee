## Pipeline

#### Dependencies:
# *through2
# *EventEmitter
# *isStream
# *lodash

through = require('through2')
EventEmitter = require('events').EventEmitter
isStream = require('isstream')
_ = require('lodash')

# Pipeline entry point
# Receives a source stream and an object describing the pipeline
Pipeline = (source, pipeline_object)->

  result = {}
  
  source.pipeline = new PipelineStreamObject(source)
  result['source'] = source

  previous_stream = source

  for key,value of pipeline_object when pipeline_object.hasOwnProperty(key)
    
    if isStream(value)
      result[key] = Flow(previous_stream, value)
      previous_stream = result[key]

    else if _.isFunction(value)
      stream_to_pipe = value.apply(result,[source,previous_stream,pipeline_object])
      result[key] = Flow(previous_stream, stream_to_pipe)
      previous_stream = result[key]

    else if _.isObject(value)
      result[key] = Pipeline(previous_stream, value)

  return result

Flow = (source, pipe)->
  source.pipe pipe
  pipe.pipeline = new PipelineStreamObject(pipe)
  return pipe 

# Appends itself to source/piped streams, as an entry point for Pipeline functionality.
# Usually appends to **stream**.pipeline object
class PipelineStreamObject extends EventEmitter

  constructor:(@parentStream)->
    super(arguments)
    @parentStream.on 'data',(data) => @emit('data',data)
    @parentStream.belongsToAPipeline = true

  aggregate:(data)->
    @aggregatedData ?= []
    @aggregatedData.push data
  
  startAggregatingData:()-> @on('data',@aggregate)

  stopAggregatingData:()-> @off('data',@aggregate)

  getAggregatedData:()-> @aggregatedData

module.exports = Pipeline