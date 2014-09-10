## Pipeline

#### Dependencies:
# *through2
# *EventEmitter
# *isStream
# *lodash

EventEmitter =       require('events').EventEmitter
isStream     =       require('./isStream.coffee')
_            =       require('lodash')
_.isStream   =       isStream

class Stream extends require('through2').ctor(objectMode: true, highWaterMark: Infinity)
  constructor:(_transform)->
    super
    @_transform = _transform if _transform?

# Reserved Keywords:
# * options

# Pipeline entry point
# Receives an object whose keys are the pipes in the pipelines(must be streams)
# Also accepts the reserved keywords above
class Pipeline

  constructor:(streams={})->

    @_isPipeline                 =   true
    (@in                         =   new Stream()).setMaxListeners 0
    (@out                        =   new Stream()).setMaxListeners 0
    @sources                     =   {}
    @pipes                       =   {}
    @pipes["__pipelineInStream"] =   @in
    @__pipelineInternalPipes     =   [name:"__pipelineInStream", stream:@in]
    @options                     =   streams.options || {}
    delete                           streams.options
    
    @debugMode(@options.debugMode) if @options.debugMode

    @add(streams)


  # Adds any number of pipes
  add:(pipes,options = {})->

    for key,value of pipes when pipes.hasOwnProperty(key)

      if isStream(value)
          @_addStream   name:key, stream:value, options:options
      else if _.isFunction(value)
        functionResult = value.apply(@, [@pipes])

        if isStream(functionResult)
          @_addStream   name:key, stream:functionResult, options:options

        else if _.isObject(functionResult)
          @_addPipeline name:key, pipelineDescriptorObject:functionResult, options:options

        else if _.isBoolean(functionResult)
          @options[key] = functionResult

      else if _.isObject(value)
          @_addPipeline   name:key, pipelineDescriptorObject:value, options:options

      else if _.isBoolean(value)
          @options[key] = value

      else
        throw new Error("Pipeline accepts streams, functions and objects as values only, key #{key} was none of those")

    return @



  # Removes any number of pipes from the pipeline and patches the leaks
  remove:(names = [])->

    if typeof names is String
        @_removeSingle names

    else if typeof names is Array
      for name in names
        @_removeSingle name

    return @

  # Add a stream before @in
  addSource:({name, stream})->

    throw @error("Source #{name} must be a stream") unless isStream(stream)
    throw @error("Source #{name} must be readable") unless isReadable(stream)

    @sources[name] = stream

    stream.pipe @in

    return @

  ## Internal, but you can extend them easily
  # Adds a single pipe
  _addStream:({name, stream, options})->

    stream.__pipelineName = name
    # Allow the streams to go on forever
    stream._readableState.highWaterMark = stream._writableState.highWaterMark = Infinity

    lastPipe = @getLastPipe()

    throw @error("Pipe #{name} must be a stream")                                             unless isStream(stream)
    throw @error("Pipe #{name} must be a writable stream")                                    unless isWritable(stream)
    throw @error("Pipe #{lastPipe.name} must be a
                       readable stream to pipe into #{name}")                                 unless isReadable(lastPipe.stream)
    console.log "Warning: pipe #{name} isn't readable. This may lead to errors"               unless isReadable(stream)
    throw @error("Pipe #{lastPipe.name} must be able to unpipe, if it is not a final stream") unless lastPipe.stream.unpipe?

    pipe from:lastPipe.stream, to:stream unless options.breakUpstream

    if !options.breakDownstream
      pipe from:stream,          to:@out

    unpipe from:lastPipe.stream, to:@out

    @__pipelineInternalPipes.push name:name, stream:stream

    @pipes[name] = stream

    return @


  # Adds a branching pipeline
  _addPipeline:({name, pipelineDescriptorObject})->

    childPipeline = new Pipeline(pipelineDescriptorObject)

    @pipes[name]                      = childPipeline
    childPipeline["__pipelineParent"] = @
    childPipeline["__pipelineName"]   = name

    if childPipeline.options.dontFork

      @_addStream
        name:    "__pipeline#{name}In"
        stream:  childPipeline.in
        options: breakDownstream:true

      @_addStream
        name:    "__pipeline#{name}Out"
        stream:  childPipeline.out
        options: breakUpstream:true

    else

      lastPipe = @getLastPipe()
      childPipeline.addSource name:"__pipelineParentSource", stream:lastPipe.stream

    return @

  removeSource:(name)->

    @sources[name].stream.unpipe @in

    delete @sources[name]

    return @

  # Removes a single pipe from the pipeline and patches the leaks
  _removeSingle:(name)->

    index = _.findIndex @__pipelineInternalPipes,         (item)-> item.name is name

    pipe_to_remove =    @__pipelineInternalPipes[index]   ?.stream

    pipe_before =       @__pipelineInternalPipes[index-1] ?.stream

    pipe_after =        @__pipelineInternalPipes[index+1] ?.stream

    if pipe_before?
      pipe_before.unpipe    pipe_to_remove

    if pipe_after?
      pipe_to_remove.unpipe pipe_after

    if pipe_before? and pipe_after?
      pipe  from: pipe_before
            to:   pipe_after.stream

    # TODO: Rearrange pipes in order to not have a sparse index
    delete @__pipelineInternalPipes[index]
    delete @pipes[name]

    return @


  # Delegate stream related functions to in and out streams
  write:          -> @in  .write          arguments...
  end:            -> @in  .end            arguments...
  _write:         -> @in  ._write         arguments...
  _transform:     -> @in  ._transform     arguments...
  _flush:         -> @in  ._flush         arguments...
  pipe:           -> @out .pipe           arguments...
  _read:          -> @out ._read          arguments...
  read:           -> @out .read           arguments...
  emit:           -> @out .emit           arguments...
  once:           -> @out .once           arguments...
  on:             -> @out .on             arguments...
  addListener:    -> @out .addListener    arguments...
  off:            -> @out .off            arguments...
  removeListener: -> @out .removeListener arguments...
  listeners:      -> @out .listeners      arguments...

  # Get helpers
  getParentPipeline: -> @__pipelineParent
  getLastPipe:       -> @__pipelineInternalPipes[-1...][0]
  getInnerPipes:     -> _.where @__pipelineInternalPipes, (pipe)-> pipe.name[0..9] isnt "__pipeline"
  get:(name)         -> @pipes[name]

  # get in/out reports from the pipeline on incoming / outgoing data.
  # You can format the data using your own function (data)-> return data
  # to use it use debugMode:true or options: debugMode:(data)-> return data
  debugMode:(format)->

    if !format? or format.constructor isnt Function
      format = (data)-> data.toString()

    @in.pipe new Stream (data, encoding, callback) =>
      callback(null, data)
      console.log "#{format(data)} coming into   #{@__pipelineName or 'Pipeline'}"

    @out.pipe new Stream (data, encoding, callback) =>
      callback(null, data)
      console.log "#{format(data)} coming out of #{@__pipelineName or 'Pipeline'}"

  error:(string)->
    string = (if @__pipelineName then "#{@__pipelineName}: " else "") + string
    new Error(string)

module.exports = Pipeline

#### Helper methods

pipe   = ({from, to})-> from.pipe   to
unpipe = ({from, to})-> from.unpipe to

# Shortcuts
isReadable = isStream.isReadable
isWritable = isStream.isWritable
isDuplex = (stream)-> return isWritable(stream) and isReadable(stream)
