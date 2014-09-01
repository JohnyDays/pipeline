Checker = (thing, what)->

  what = readyWhat(what)

  for key,value of what when what.hasOwnProperty(key) and key isnt 'constructor'

    return false if !thing[key]?

    return false if !Checker thing[key], value

  return true

Checker.any = ->

Checker.any:: = {}

module.exports = Checker
# Internal helper methods
isArray   = (thing)  -> thing instanceof Array
isString  = (thing)  -> thing instanceof String

readyWhat = (what)   ->

  throw new Error("You must check for something
                   a.k.a second argument must be defined") if !what?
  if isString what
    what = [what]
  if isArray what

    newWhat = ->

    for method in what

      newWhat::[method] = Checker.any

    what = newWhat




  return what::
