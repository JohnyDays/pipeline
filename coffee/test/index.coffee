through = require('through2')
_ = require('lodash')
_.isStream = require('isStream')
pipe = require('../../index.js')
should = require('should')
event_stream = require('event-stream')
describe "Pipeline", ->
  
  pipes = null 
  
  it "Creates a pipeline from a source stream and an object describing the pipeline", ->
    
    source = through()

    pipes = pipe source,

                    step1:through()

                    step2:through()  

                    step3:through()

    _.isStream pipes.step1
     .should.be.ok
    
    _.isStream pipes.step2
     .should.be.ok

    _.isStream pipes.step3
     .should.be.ok


  it "Can aggregate data", ->
    
    pipes.step1.pipeline.startAggregatingData()
    pipes.step3.pipeline.startAggregatingData()

    pipes.source.emit('data','a')
    
    _.isEqual(
      pipes.step1.pipeline.getAggregatedData(), 
      pipes.step3.pipeline.getAggregatedData()
    ).should.be.ok

    pipes.step2.emit('data','a')

    _.isEqual(
      pipes.step1.pipeline.getAggregatedData(), 
      pipes.step3.pipeline.getAggregatedData()
    ).should.not.be.ok


  it "Supports objects in the description, and pipes them from the previous step", ->

    source = through()

    pipes = pipe source,
                       
                    step1:  through()
                    step2:  through()
                    branch: 
                      step1:through()
                      step2:through()
                    step3:  through()


    pipes.source      .pipeline.startAggregatingData()
    pipes.step1       .pipeline.startAggregatingData()
    pipes.step2       .pipeline.startAggregatingData()
    pipes.branch.step1.pipeline.startAggregatingData()
    pipes.branch.step2.pipeline.startAggregatingData()
    pipes.step3       .pipeline.startAggregatingData()

    pipes.step1.emit('data','a')

    # Should go through to step 2 and into the branches
    _.isEqual(
      pipes.branch.step1.pipeline.getAggregatedData(),
      pipes.step2       .pipeline.getAggregatedData()
    ).should.be.ok

    # Should go through both steps of the branches
    _.isEqual(
      pipes.branch.step1.pipeline.getAggregatedData(),
      pipes.branch.step2.pipeline.getAggregatedData()
    ).should.be.ok

    pipes.branch.step1.emit('data','a')

    # Should not leak to step 3
    _.isEqual(
      pipes.step3       .pipeline.getAggregatedData(),
      pipes.branch.step2.pipeline.getAggregatedData()
    ).should.not.be.ok


  it "Supports functions in the description", ->

    source = through()

    pipes = pipe source,
                 step1:through()
                 step2:->through()
                 branch:
                  step1:through()
                 step3:->through()
                 step4:(source, pipeline_object)-> event_stream.merge(@step1, @branch.step1)


    pipes.step4.pipeline.startAggregatingData()

    source.emit('data','a')
    
    # Should get piped data from step1, branch.step1 and itself
    pipes.step4.pipeline.getAggregatedData().length.should.equal 3

