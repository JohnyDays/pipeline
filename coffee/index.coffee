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
# Receives an object whose keys are the pipes in the pipelines(must be streams)
class Pipeline
  constructor:(streams={})->
    
    @pipes = {}
    @_internal_pipe_array = []
    @_isPipeline = true
    @add(streams)

  # Adds any number of pipes
  add:(pipes)->
    for key,value of pipes when pipes.hasOwnProperty(key)
      if _.isStream(value)
        @addSingle
          name:key
          stream:value
      else if _.isFunction(value)
        @addSingle
          name:key
          stream:value.apply(@, [@pipes])
      else if _.isObject(value)
        @addPipeline value
      else
        throw new Error("Pipeline accepts streams, functions and objects as values only, key #{key} was none of those")

    return @
    
  # Adds a single pipe
  addSingle:({name,stream})->
    
    if !isStream(stream)
      throw new Error("Pipe #{name} must be a stream")

    if @_internal_pipe_array.length is 0
      @_internal_pipe_array.push name:name, stream:stream
      @pipes[name] = stream
      return stream
    
    if !isWritable(stream)
      throw new Error("Pipe #{name} must be a writable stream")
    
    [..., last_pipe] = @_internal_pipe_array

    if !isReadable(last_pipe.stream)
      throw new Error("Pipe #{last_pipe.name} must be a readable stream to pipe into #{name}")

    console.log "Piping from #{last_pipe.name} to #{name}"
    pipe from:last_pipe.stream, to:stream
    
    @_internal_pipe_array.push name:name, stream:stream
    @pipes[name] = stream
    return @


  # Adds a branching pipeline
  addPipeline:(pipes)->
    
    pipeline = new Pipeline()
    
    [...,last_pipe] = @_internal_pipe_array
    
    if last_pipe
      pipeline.add("__pipeline_source_stream":last_pipe)

    pipeline.add pipes

    return @


  # Removes any number of pipes from the pipeline and patches the leaks
  remove:(names = [])->
    for name in names
      @removeSingle(name)

    return @

  # Removes a single pipe from the pipeline and patches the leaks
  removeSingle:(name)->
    
    index = _.findIndex(@_internal_pipe_array, (item)-> item.name is name )
    
    pipe_to_remove = @_internal_pipe_array[index]

    pipe_before = @_internal_pipe_array[index-1]
    
    pipe_after = @_internal_pipe_array[index+1]

    if pipe_before?.stream?
      pipe_before.stream.unpipe pipe_to_remove

    if pipe_after?.stream?
      pipe_to_remove.stream.unpipe pipe_after

    if pipe_before?.stream? and pipe_after?.stream?
      pipe from:pipe_before, to:pipe_after

    # TODO: Rearrange pipes in order to not have a sparse index
    delete @_internal_pipe_array[index]
    delete @pipes[name]

    return @

  emit:-> @_internal_pipe_array[0].stream.emit(arguments...)

module.exports = Pipeline

#### Helper methods

pipe = ({from, to})-> from.pipe to

# Shortcuts
isReadable = isStream.isReadable
isWritable = isStream.isWritable
isDuplex = (stream)-> return isWritable(stream) and isReadable(stream)