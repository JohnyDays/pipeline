require('../register')('implements')
require 'should'

natives = require('../sources/nativeInterfaces.coffee')

describe "Checker",->

  it "Works on native objects", ->

    {}   .implements      natives.Object

    (5)  .implements      natives.Number

    (->) .implements      natives.Function

    (->) .doesntImplement natives.Number

  it "Works on custom classes", ->

    class A
      doThing:->

    class B extends A
      doOtherThing:->

    a = new A()

    b = new B()

    a .implements      A

    a .doesntImplement B

    b .implements      B

    b .implements      A

  it "Works with deep inheritance", ->

    class A
      doThing:->

    class B extends A

    class C extends B

    c = new C()

    c .implements A

  it "Works with interface style programming", ->

    class Stream
      read:->
      write:->

    class StreamImplementor
      read:->
      write:->@implementationSpecificFunction()
      implementationSpecificFunction:->

    stream = new StreamImplementor()

    stream .implements Stream

  it "Can directly receive an array or string", ->

    a = []

    a .implements 'indexOf'
    a .implements ['indexOf','forEach']


# For more semantic tests
oldImplements                    = Object.prototype.implements
Object.prototype.implements      = -> oldImplements.apply(@,arguments).should.equal true
Object.prototype.doesntImplement = -> oldImplements.apply(@,arguments).should.equal false
