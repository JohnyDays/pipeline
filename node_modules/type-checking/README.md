# Type Checking
> **Check for what you need**

> Mainly for framework developers,
although it is just as usable in an app

## Installation
    npm install --save type-checking

## Usage

* By registering (recommended, but can cause conflicts)

```coffeescript

  require('type-checking/register')('responds_to')

  array = []

  array.responds_to 'indexOf' #true
  array.responds_to ['indexOf','join','concat'] #true

  class ArrayInterface
    indexOf:->
    join:->
    concat:->

  array.responds_to ArrayInterface #true

```

* Directly

```coffeescript

  responds_to = require 'type-checking'

  array = []

  responds_to array, 'indexOf' #true

```
