class Stream extends require('through2').obj
_ = require('lodash')
_.isStream = require('isStream')
Pipeline = require('../../index.js')
should = require('should')
event_stream = require('event-stream')
describe "Pipeline", ->
  
  pipeline = null 
  beforeEach ->
    pipeline = new Pipeline
      source:  new Stream()
      step1:   new Stream()
      step2:   new Stream()

  it "Creates a pipeline", (done)->
    
    pipeline.pipes.step2.on 'data', (data)->
      data.should.equal 1
      done()

    pipeline.write 1

  it "Adds pipes at any time", (done)->
    
    pipeline.add step3:new Stream()

    pipeline.pipes.step3.on 'data', (data)->
      data.should.equal 2
      done()
    
    pipeline.write 2

  it "Supports objects, and creates a branching pipeline from them", (done)->

    pipeline.add 
      branch:
        step1: new Stream()
        step2: new Stream()

    branch = pipeline.pipes.branch

    branch.pipes.step1.on 'data', (data)->
      data.should.equal 3
      done()

    pipeline.write 3


  it "Supports functions", (done)->

    pipeline.add
      branch:
        step1:-> new Stream()
        step2:-> new Stream()

    branch = pipeline.pipes.branch

    branch.pipes.step1.on 'data', (data)->
      data.should.equal 4
      done()

    pipeline.write 4

  it "Can remove any step and automatically patch the leak", (done)->

    pipeline.remove("step1")

    pipeline.pipes.step2.on 'data', (data)->
      data.should.equal 5
      done()

    pipeline.write 5

  it "Supports write, pipe, emit, end aliases", (done)->

    wait = _.after 3, done

    stream = new Stream()

    pipeline.pipes.source.on 'data', (data)->
      data.should.equal 1
      wait()

    pipeline.pipe stream 

    stream.on 'data', (data)->
      data.should.equal 1
      wait()
      
    pipeline.write 1

    pipeline.out.on 'finish', -> wait() 
    
    pipeline.end()



  it "Supports special options defined as booleans", ->

    pipeline.add
      test_option:true

    pipeline.options.test_option.should.equal true    
