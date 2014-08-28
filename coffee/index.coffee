## Pipeline

#### Dependencies:
# *through2
# *EventEmitter
# *isStream
# *lodash

class Stream extends require('through2').obj
EventEmitter =       require('events').EventEmitter
isStream =           require('isstream')
_ =                  require('lodash')


# Pipeline entry point
# Receives an object whose keys are the pipes in the pipelines(must be streams)
class Pipeline
  constructor:(streams={})->
    @in =  new Stream()
    @out = new Stream()
    @pipes =   {}
    @options = {}
    @__pipelineInternalPipes = [name:"__pipeline_in_stream", stream:@in]
    @pipes["__pipeline_in_stream"] = @in
    @_isPipeline = true
    @add(streams)

  # Adds any number of pipes
  add:(pipes)->
    for key,value of pipes when pipes.hasOwnProperty(key)
      if      _.isStream(value)
        @addSingle
          name:key
          stream:value

      else if _.isFunction(value)
        @addSingle
          name:key
          stream:value.apply(@, [@pipes])

      else if _.isObject(value)
        @addPipeline 
          name:key
          object:value
          
      else if _.isBoolean(value)
        @options[key] = value
      else
        throw new Error("Pipeline accepts streams, functions and objects as values only, key #{key} was none of those")

    return @
    
  # Adds a single pipe
  addSingle:({name,stream})->
    
    if !isStream(stream)
      throw new Error("Pipe #{name} must be a stream")

    if !isWritable(stream)
      throw new Error("Pipe #{name} must be a writable stream")
    
    [..., last_pipe] = @__pipelineInternalPipes

    if !isReadable(last_pipe.stream)
      throw new Error("Pipe #{last_pipe.name} must be a readable stream to pipe into #{name}")

    pipe from:last_pipe.stream, to:stream

    if isReadable(stream)
      unpipe from:last_pipe.stream, to:@out
      pipe from:stream, to:@out

    @__pipelineInternalPipes.push name:name, stream:stream
    @pipes[name] = stream
    return @


  # Adds a branching pipeline
  addPipeline:({name, object})->
    
    pipeline = new Pipeline()
    
    [...,last_pipe] = @__pipelineInternalPipes
    
    if last_pipe
      pipeline.add("__pipelineSourceStream":last_pipe.stream)

    pipeline.add object
    
    @pipes[name] = pipeline

    pipeline["__pipelineParent"] = @

    return @


  # Removes any number of pipes from the pipeline and patches the leaks
  remove:(names = [])->
    if typeof names is String
      @removeSingle names
    else if typeof names is Array
      for name in names
        @removeSingle(name)

    return @

  # Removes a single pipe from the pipeline and patches the leaks
  removeSingle:(name)->
    
    index = _.findIndex(@__pipelineInternalPipes, (item)-> item.name is name )
    
    pipe_to_remove = @__pipelineInternalPipes[index]

    pipe_before =    @__pipelineInternalPipes[index-1]
    
    pipe_after =     @__pipelineInternalPipes[index+1]

    if pipe_before?.stream?
      pipe_before.stream.unpipe    pipe_to_remove

    if pipe_after?.stream?
      pipe_to_remove.stream.unpipe pipe_after

    if pipe_before?.stream? and pipe_after?.stream?
      pipe from:pipe_before, to:pipe_after

    # TODO: Rearrange pipes in order to not have a sparse index
    delete @__pipelineInternalPipes[index]
    delete @pipes[name]

    return @

  emit:->  @in.emit  arguments...
  write:-> @in.write arguments...
  end:->   @in.end   arguments...

  getParentPipeline:-> @__pipelineParent

module.exports = Pipeline

#### Helper methods

pipe =   ({from, to})-> from.pipe   to
unpipe = ({from, to})-> from.unpipe to

# Shortcuts
isReadable = isStream.isReadable
isWritable = isStream.isWritable
isDuplex = (stream)-> return isWritable(stream) and isReadable(stream)