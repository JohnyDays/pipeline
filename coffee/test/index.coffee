
class StorageStream extends require('through2').ctor({ objectMode: true, highWaterMark: 16 })
_ = require('lodash')
_.isStream = require('isStream')
Pipeline = require('../../index.js')
should = require('should')
event_stream = require('event-stream')
# Change this line to get in/out reports from the pipeline
debug = false
# A stream that stores all the data that has passed through it, for testing
class StorageStream extends StorageStream
  constructor:->
    super
    @stored = []
  _transform:(content, encoding, callback)->
    callback(null,content)
    @stored.push content

describe "Pipeline", ->
  
  pipeline = null 

  beforeEach ->
    pipeline = new Pipeline
      source:  new StorageStream()
      step1:   new StorageStream()
      step2:   new StorageStream()
      options:
        debugMode:debug

  it "Creates a pipeline", (done)->

    pipeline.write 1

    _.delay ->
      pipeline.pipes.source.stored.should.eql [1]
      done()

  it "Adds pipes at any time", (done)->
    
    pipeline.add step3:new StorageStream()

    
    pipeline.write 2

    _.delay ->
      pipeline.pipes.step3.stored.should.eql [2]
      done()

  it "Supports objects, and creates a branching pipeline from them", (done)->

    pipeline.add 
      branch:
        step1: new StorageStream()
        step2: new StorageStream()
        options:
          debugMode:debug

    branch = pipeline.pipes.branch

    pipeline.write 3

    _.delay ->
      branch.pipes.step1.stored.should.eql [3]
      done()



  it "Supports functions", (done)->

    pipeline.add
      branch:
        step1:-> new StorageStream()
        step2:-> new StorageStream()

    branch = pipeline.pipes.branch

    pipeline.write 4

    _.delay ->
      branch.pipes.step1.stored.should.eql [4]
      done()


  it "Can remove any step and automatically patch the leak", (done)->

    pipeline.remove("step1")

    _.delay ->
      pipeline.pipes.step2.stored.should.eql [5]
      done()

    pipeline.write 5

  it "Supports write, pipe, emit, end aliases", (reallyDone)->

    done = _.after 3, reallyDone

    stream = new StorageStream()

    _.delay ->
      pipeline.pipes.source.stored.should.eql [1]
      done()

    pipeline.pipe stream

    _.delay ->
      stream.stored.should.eql [1]
      done()
      
    pipeline.write 1

    pipeline.out.on 'finish', -> done() 
    
    pipeline.end()



  it "Supports special options defined as booleans or in the options object", ->

    pipeline.add
      test_option:true

    pipeline.options.test_option.should.equal true

    pipeline = new Pipeline options: test_option:true
    
    pipeline.options.test_option.should.equal true

  it "Supports non-forking branches", (done)->

    pipeline.add
      branch:
        step1:    new StorageStream()
        step2:    new StorageStream()
        options:
          debugMode:debug
          dontFork: true
      after:      new StorageStream()

    pipeline.write 5
    
    _.delay ->

      pipeline.pipes.after.stored.should.eql [5]

      pipeline.pipes.branch.write 5

      _.delay ->

        pipeline.pipes.after.stored.should.eql [5,5]
        done()


