through = require('through2').obj
_ = require('lodash')
_.isStream = require('isStream')
Pipeline = require('../../index.js')
should = require('should')
event_stream = require('event-stream')
describe "Pipeline", ->
  
  pipeline = null 
  
  it "Creates a pipeline", (done)->
    
    pipeline = new Pipeline
      source: through()
      step1:  through()
      step2:  through()

    pipeline.pipes.step1.on 'data', (data)->
      data.should.equal 4
      done()
    console.log pipeline.pipes.step1
    pipeline.emit 'data', 4

  it "Adds pipes at any time", (done)->
    
    pipeline.add step3:through()

    pipeline.pipes.step3.on 'data', (data)->
      data.should.equal 4
      done()
    
    pipeline.emit 'data',4

  it "Supports objects, and creates a branching pipeline from them", (done)->

    pipeline.add 
      branch:
        step1: through()
        step2: through()

    branch = pipeline.pipes.branch

    branch.pipes.step1.on 'data', (data)->
      data.should.equal 5
      done()
    pipeline.emit 'data',5

  it "Supports functions in the description", ->