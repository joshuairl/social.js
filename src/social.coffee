# **Social.coffee
# (c) 2012 Joshua F. Rountree**
# Social.js is freely distributable under the terms of the
# [MIT license](http://en.wikipedia.org/wiki/MIT_License).
# Portions of social.js are inspired by or borrowed from
# [social-js-api](https://github.com/tyaga/social-js-api
# For all details and documentation:
# https://github.com/JoshuaIRL/social.js

# Baseline setup
# --------------

# Establish the root object, `window` in the browser, or `global` on the server.
root = this

# Save the previous value of the `Social` variable.
previousSocial = root.Social

# Establish the object that gets thrown to break out of a loop iteration.
# `StopIteration` is SOP on Mozilla.
breaker = if typeof(StopIteration) is 'undefined' then '__break__' else StopIteration

# Helper function to escape **RegExp** contents, because JS doesn't have one.
escapeRegExp = (string) -> string.replace(/([.*+?^${}()|[\]\/\\])/g, '\\$1')

# Save bytes in the minified (but not gzipped) version:
ArrayProto           = Array.prototype
ObjProto             = Object.prototype

# Create quick reference variables for speed access to core prototypes.
slice                = ArrayProto.slice
unshift              = ArrayProto.unshift
toString             = ObjProto.toString
hasOwnProperty       = ObjProto.hasOwnProperty
propertyIsEnumerable = ObjProto.propertyIsEnumerable


# All **ECMA5** native implementations we hope to use are declared here.
nativeForEach        = ArrayProto.forEach
nativeMap            = ArrayProto.map
nativeReduce         = ArrayProto.reduce
nativeReduceRight    = ArrayProto.reduceRight
nativeFilter         = ArrayProto.filter
nativeEvery          = ArrayProto.every
nativeSome           = ArrayProto.some
nativeIndexOf        = ArrayProto.indexOf
nativeLastIndexOf    = ArrayProto.lastIndexOf
nativeIsArray        = Array.isArray
nativeKeys           = Object.keys


# Create a safe reference to the Social object for use below.
Social = (obj) -> new wrapper(obj)

# Export the Social object for **CommonJS**.
if typeof(exports) != 'undefined' then exports.Social = Social


# Export Social to global scope.
root.Social = So = Social

# Current version.
So.VERSION = '0.1'


# Collection Functions
# --------------------

# The cornerstone, an **each** implementation.
# Handles objects implementing **forEach**, arrays, and raw objects.
So.util.each = (obj, iterator, context) ->
  try
    if nativeForEach and obj.forEach is nativeForEach
      obj.forEach iterator, context
    else if So.util.isNumber obj.length
      iterator.call context, obj[i], i, obj for i in [0...obj.length]
    else
      iterator.call context, val, key, obj  for own key, val of obj
  catch e
    throw e if e isnt breaker
  obj


# Return the results of applying the iterator to each element. Use JavaScript
# 1.6's version of **map**, if possible.
So.util.map = (obj, iterator, context) ->
  return obj.map(iterator, context) if nativeMap and obj.map is nativeMap
  results = []
  So.util.each obj, (value, index, list) ->
    results.push iterator.call context, value, index, list
  results


# **Reduce** builds up a single result from a list of values. Also known as
# **inject**, or **foldl**. Uses JavaScript 1.8's version of **reduce**, if possible.
So.util.reduce = (obj, iterator, memo, context) ->
  if nativeReduce and obj.reduce is nativeReduce
    iterator = So.util.bind iterator, context if context
    return obj.reduce iterator, memo
  So.util.each obj, (value, index, list) ->
    memo = iterator.call context, memo, value, index, list
  memo


# The right-associative version of **reduce**, also known as **foldr**. Uses
# JavaScript 1.8's version of **reduceRight**, if available.
So.util.reduceRight = (obj, iterator, memo, context) ->
  if nativeReduceRight and obj.reduceRight is nativeReduceRight
    iterator = So.util.bind iterator, context if context
    return obj.reduceRight iterator, memo
  reversed = So.util.clone(So.util.toArray(obj)).reverse()
  So.util.reduce reversed, iterator, memo, context


# Return the first value which passes a truth test.
So.util.detect = (obj, iterator, context) ->
  result = null
  So.util.each obj, (value, index, list) ->
    if iterator.call context, value, index, list
      result = value
      So.util.breakLoop()
  result


# Return all the elements that pass a truth test. Use JavaScript 1.6's
# **filter**, if it exists.
So.util.filter = (obj, iterator, context) ->
  return obj.filter iterator, context if nativeFilter and obj.filter is nativeFilter
  results = []
  So.util.each obj, (value, index, list) ->
    results.push value if iterator.call context, value, index, list
  results


# Return all the elements for which a truth test fails.
So.util.reject = (obj, iterator, context) ->
  results = []
  So.util.each obj, (value, index, list) ->
    results.push value if not iterator.call context, value, index, list
  results


# Determine whether all of the elements match a truth test. Delegate to
# JavaScript 1.6's **every**, if it is present.
So.util.every = (obj, iterator, context) ->
  iterator ||= So.util.identity
  return obj.every iterator, context if nativeEvery and obj.every is nativeEvery
  result = true
  So.util.each obj, (value, index, list) ->
    So.util.breakLoop() unless (result = result and iterator.call(context, value, index, list))
  result


# Determine if at least one element in the object matches a truth test. Use
# JavaScript 1.6's **some**, if it exists.
So.util.some = (obj, iterator, context) ->
  iterator ||= So.util.identity
  return obj.some iterator, context if nativeSome and obj.some is nativeSome
  result = false
  So.util.each obj, (value, index, list) ->
    So.util.breakLoop() if (result = iterator.call(context, value, index, list))
  result


# Determine if a given value is included in the array or object,
# based on `===`.
So.util.include = (obj, target) ->
  return So.util.indexOf(obj, target) isnt -1 if nativeIndexOf and obj.indexOf is nativeIndexOf
  return true for own key, val of obj when val is target
  false


# Invoke a method with arguments on every item in a collection.
So.util.invoke = (obj, method) ->
  args = So.util.rest arguments, 2
  (if method then val[method] else val).apply(val, args) for val in obj


# Convenience version of a common use case of **map**: fetching a property.
So.util.pluck = (obj, key) ->
  So.util.map(obj, (val) -> val[key])


# Return the maximum item or (item-based computation).
So.util.max = (obj, iterator, context) ->
  return Math.max.apply(Math, obj) if not iterator and So.util.isArray(obj)
  result = computed: -Infinity
  So.util.each obj, (value, index, list) ->
    computed = if iterator then iterator.call(context, value, index, list) else value
    computed >= result.computed and (result = {value: value, computed: computed})
  result.value


# Return the minimum element (or element-based computation).
So.util.min = (obj, iterator, context) ->
  return Math.min.apply(Math, obj) if not iterator and So.util.isArray(obj)
  result = computed: Infinity
  So.util.each obj, (value, index, list) ->
    computed = if iterator then iterator.call(context, value, index, list) else value
    computed < result.computed and (result = {value: value, computed: computed})
  result.value


# Sort the object's values by a criterion produced by an iterator.
So.util.sortBy = (obj, iterator, context) ->
  So.util.pluck(((So.util.map obj, (value, index, list) ->
    {value: value, criteria: iterator.call(context, value, index, list)}
  ).sort((left, right) ->
    a = left.criteria; b = right.criteria
    if a < b then -1 else if a > b then 1 else 0
  )), 'value')


# Use a comparator function to figure out at what index an object should
# be inserted so as to maintain order. Uses binary search.
So.util.sortedIndex = (array, obj, iterator) ->
  iterator ||= So.util.identity
  low =  0
  high = array.length
  while low < high
    mid = (low + high) >> 1
    if iterator(array[mid]) < iterator(obj) then low = mid + 1 else high = mid
  low


# Convert anything iterable into a real, live array.
So.util.toArray = (iterable) ->
  return []                   if (!iterable)
  return iterable.toArray()   if (iterable.toArray)
  return iterable             if (So.util.isArray(iterable))
  return slice.call(iterable) if (So.util.isArguments(iterable))
  So.util.values(iterable)


# Return the number of elements in an object.
So.util.size = (obj) -> So.util.toArray(obj).length


# Array Functions
# ---------------

# Get the first element of an array. Passing `n` will return the first N
# values in the array. Aliased as **head**. The `guard` check allows it to work
# with **map**.
So.util.first = (array, n, guard) ->
  if n and not guard then slice.call(array, 0, n) else array[0]


# Returns everything but the first entry of the array. Aliased as **tail**.
# Especially useful on the arguments object. Passing an `index` will return
# the rest of the values in the array from that index onward. The `guard`
# check allows it to work with **map**.
So.util.rest = (array, index, guard) ->
  slice.call(array, if So.util.isUndefined(index) or guard then 1 else index)


# Get the last element of an array.
So.util.last = (array) -> array[array.length - 1]


# Trim out all falsy values from an array.
So.util.compact = (array) -> item for item in array when item


# Return a completely flattened version of an array.
So.util.flatten = (array) ->
  So.util.reduce array, (memo, value) ->
    return memo.concat(So.util.flatten(value)) if So.util.isArray value
    memo.push value
    memo
  , []


# Return a version of the array that does not contain the specified value(s).
So.util.without = (array) ->
  values = So.util.rest arguments
  val for val in So.util.toArray(array) when not So.util.include values, val


# Produce a duplicate-free version of the array. If the array has already
# been sorted, you have the option of using a faster algorithm.
So.util.uniq = (array, isSorted) ->
  memo = []
  for el, i in So.util.toArray array
    memo.push el if i is 0 || (if isSorted is true then So.util.last(memo) isnt el else not So.util.include(memo, el))
  memo


# Produce an array that contains every item shared between all the
# passed-in arrays.
So.util.intersect = (array) ->
  rest = So.util.rest arguments
  So.util.select So.util.uniq(array), (item) ->
    So.util.all rest, (other) ->
      So.util.indexOf(other, item) >= 0


# Zip together multiple lists into a single array -- elements that share
# an index go together.
So.util.zip = ->
  length =  So.util.max So.util.pluck arguments, 'length'
  results = new Array length
  for i in [0...length]
    results[i] = So.util.pluck arguments, String i
  results


# If the browser doesn't supply us with **indexOf** (I'm looking at you, MSIE),
# we need this function. Return the position of the first occurrence of an
# item in an array, or -1 if the item is not included in the array.
So.util.indexOf = (array, item) ->
  return array.indexOf item if nativeIndexOf and array.indexOf is nativeIndexOf
  i = 0; l = array.length
  while l - i
    if array[i] is item then return i else i++
  -1


# Provide JavaScript 1.6's **lastIndexOf**, delegating to the native function,
# if possible.
So.util.lastIndexOf = (array, item) ->
  return array.lastIndexOf(item) if nativeLastIndexOf and array.lastIndexOf is nativeLastIndexOf
  i = array.length
  while i
    if array[i] is item then return i else i--
  -1


# Generate an integer Array containing an arithmetic progression. A port of
# [the native Python **range** function](http://docs.python.org/library/functions.html#range).
So.util.range = (start, stop, step) ->
  a         = arguments
  solo      = a.length <= 1
  i = start = if solo then 0 else a[0]
  stop      = if solo then a[0] else a[1]
  step      = a[2] or 1
  len       = Math.ceil((stop - start) / step)
  return []   if len <= 0
  range     = new Array len
  idx       = 0
  loop
    return range if (if step > 0 then i - stop else stop - i) >= 0
    range[idx] = i
    idx++
    i+= step


# Function Functions
# ------------------

# Create a function bound to a given object (assigning `this`, and arguments,
# optionally). Binding with arguments is also known as **curry**.
So.util.bind = (func, obj) ->
  args = So.util.rest arguments, 2
  -> func.apply obj or root, args.concat arguments


# Bind all of an object's methods to that object. Useful for ensuring that
# all callbacks defined on an object belong to it.
So.util.bindAll = (obj) ->
  funcs = if arguments.length > 1 then So.util.rest(arguments) else So.util.functions(obj)
  So.util.each funcs, (f) -> obj[f] = So.util.bind obj[f], obj
  obj


# Delays a function for the given number of milliseconds, and then calls
# it with the arguments supplied.
So.util.delay = (func, wait) ->
  args = So.util.rest arguments, 2
  setTimeout((-> func.apply(func, args)), wait)


# Memoize an expensive function by storing its results.
So.util.memoize = (func, hasher) ->
  memo = {}
  hasher or= So.util.identity
  ->
    key = hasher.apply this, arguments
    return memo[key] if key of memo
    memo[key] = func.apply this, arguments


# Defers a function, scheduling it to run after the current call stack has
# cleared.
So.util.defer = (func) ->
  So.util.delay.apply _, [func, 1].concat So.util.rest arguments


# Returns the first function passed as an argument to the second,
# allowing you to adjust arguments, run code before and after, and
# conditionally execute the original function.
So.util.wrap = (func, wrapper) ->
  -> wrapper.apply wrapper, [func].concat arguments


# Returns a function that is the composition of a list of functions, each
# consuming the return value of the function that follows.
So.util.compose = ->
  funcs = arguments
  ->
    args = arguments
    for i in [funcs.length - 1..0] by -1
      args = [funcs[i].apply(this, args)]
    args[0]


# Object Functions
# ----------------

# Retrieve the names of an object's properties.
So.util.keys = nativeKeys or (obj) ->
  return So.util.range 0, obj.length if So.util.isArray(obj)
  key for key, val of obj


# Retrieve the values of an object's properties.
So.util.values = (obj) ->
  So.util.map obj, So.util.identity


# Return a sorted list of the function names available in Social.
So.util.functions = (obj) ->
  So.util.filter(So.util.keys(obj), (key) -> So.util.isFunction(obj[key])).sort()


# Extend a given object with all of the properties in a source object.
So.util.extend = (obj) ->
  for source in So.util.rest(arguments)
    obj[key] = val for key, val of source
  obj


# Create a (shallow-cloned) duplicate of an object.
So.util.clone = (obj) ->
  return obj.slice 0 if So.util.isArray obj
  So.util.extend {}, obj


# Invokes interceptor with the obj, and then returns obj.
# The primary purpose of this method is to "tap into" a method chain, in order to perform operations on intermediate results within the chain.
So.util.tap = (obj, interceptor) ->
  interceptor obj
  obj


# Perform a deep comparison to check if two objects are equal.
So.util.isEqual = (a, b) ->
  # Check object identity.
  return true if a is b
  # Different types?
  atype = typeof(a); btype = typeof(b)
  return false if atype isnt btype
  # Basic equality test (watch out for coercions).
  return true if `a == b`
  # One is falsy and the other truthy.
  return false if (!a and b) or (a and !b)
  # One of them implements an `isEqual()`?
  return a.isEqual(b) if a.isEqual
  # Check dates' integer values.
  return a.getTime() is b.getTime() if So.util.isDate(a) and So.util.isDate(b)
  # Both are NaN?
  return false if So.util.isNaN(a) and So.util.isNaN(b)
  # Compare regular expressions.
  if So.util.isRegExp(a) and So.util.isRegExp(b)
    return a.source     is b.source and
           a.global     is b.global and
           a.ignoreCase is b.ignoreCase and
           a.multiline  is b.multiline
  # If a is not an object by this point, we can't handle it.
  return false if atype isnt 'object'
  # Check for different array lengths before comparing contents.
  return false if a.length and (a.length isnt b.length)
  # Nothing else worked, deep compare the contents.
  aKeys = So.util.keys(a); bKeys = So.util.keys(b)
  # Different object sizes?
  return false if aKeys.length isnt bKeys.length
  # Recursive comparison of contents.
  return false for key, val of a when !(key of b) or !So.util.isEqual(val, b[key])
  true


# Is a given array or object empty?
So.util.isEmpty = (obj) ->
  return obj.length is 0 if So.util.isArray(obj) or So.util.isString(obj)
  return false for own key of obj
  true


# Is a given value a DOM element?
So.util.isElement   = (obj) -> obj and obj.nodeType is 1


# Is a given value an array?
So.util.isArray     = nativeIsArray or (obj) -> !!(obj and obj.concat and obj.unshift and not obj.callee)


# Is a given variable an arguments object?
So.util.isArguments = (obj) -> obj and obj.callee


# Is the given value a function?
So.util.isFunction  = (obj) -> !!(obj and obj.constructor and obj.call and obj.apply)


# Is the given value a string?
So.util.isString    = (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))


# Is a given value a number?
So.util.isNumber    = (obj) -> (obj is +obj) or toString.call(obj) is '[object Number]'


# Is a given value a boolean?
So.util.isBoolean   = (obj) -> obj is true or obj is false


# Is a given value a Date?
So.util.isDate      = (obj) -> !!(obj and obj.getTimezoneOffset and obj.setUTCFullYear)


# Is the given value a regular expression?
So.util.isRegExp    = (obj) -> !!(obj and obj.exec and (obj.ignoreCase or obj.ignoreCase is false))


# Is the given value NaN -- this one is interesting. `NaN != NaN`, and
# `isNaN(undefined) == true`, so we make sure it's a number first.
So.util.isNaN       = (obj) -> So.util.isNumber(obj) and window.isNaN(obj)


# Is a given value equal to null?
So.util.isNull      = (obj) -> obj is null


# Is a given variable undefined?
So.util.isUndefined = (obj) -> typeof obj is 'undefined'


# Utility Functions
# -----------------

# Run Social.js in noConflict mode, returning the `_` variable to its
# previous owner. Returns a reference to the Social object.
So.util.noConflict = ->
  root._ = previousSocial
  this


# Keep the identity function around for default iterators.
So.util.identity = (value) -> value


# Run a function `n` times.
So.util.times = (n, iterator, context) ->
  iterator.call context, i for i in [0...n]


# Break out of the middle of an iteration.
So.util.breakLoop = -> throw breaker


# Add your own custom functions to the Social object, ensuring that
# they're correctly added to the OOP wrapper as well.
So.util.mixin = (obj) ->
  for name in So.util.functions(obj)
    addToWrapper name, _[name] = obj[name]


# Generate a unique integer id (unique within the entire client session).
# Useful for temporary DOM ids.
idCounter = 0
So.util.uniqueId = (prefix) ->
  (prefix or '') + idCounter++


# By default, Social uses **ERB**-style template delimiters, change the
# following template settings to use alternative delimiters.
So.util.templateSettings = {
  start:        '<%'
  end:          '%>'
  interpolate:  /<%=(.+?)%>/g
}


# JavaScript templating a-la **ERB**, pilfered from John Resig's
# *Secrets of the JavaScript Ninja*, page 83.
# Single-quote fix from Rick Strahl.
# With alterations for arbitrary delimiters, and to preserve whitespace.
So.util.template = (str, data) ->
  c = So.util.templateSettings
  endMatch = new RegExp("'(?=[^"+c.end.substr(0, 1)+"]*"+escapeRegExp(c.end)+")","g")
  fn = new Function 'obj',
    'var p=[],print=function(){p.push.apply(p,arguments);};' +
    'with(obj||{}){p.push(\'' +
    str.replace(/\r/g, '\\r')
       .replace(/\n/g, '\\n')
       .replace(/\t/g, '\\t')
       .replace(endMatch,"✄")
       .split("'").join("\\'")
       .split("✄").join("'")
       .replace(c.interpolate, "',$1,'")
       .split(c.start).join("');")
       .split(c.end).join("p.push('") +
       "');}return p.join('');"
  if data then fn(data) else fn


# Aliases
# -------

So.util.forEach  = So.util.each
So.util.foldl    = So.util.inject = So.util.reduce
So.util.foldr    = So.util.reduceRight
So.util.select   = So.util.filter
So.util.all      = So.util.every
So.util.any      = So.util.some
So.util.contains = So.util.include
So.util.head     = So.util.first
So.util.tail     = So.util.rest
So.util.methods  = So.util.functions


# Setup the OOP Wrapper
# ---------------------

# If Social is called as a function, it returns a wrapped object that
# can be used OO-style. This wrapper holds altered versions of all the
# Social functions. Wrapped objects may be chained.
wrapper = (obj) ->
  this._wrapped = obj
  this


# Helper function to continue chaining intermediate results.
result = (obj, chain) ->
  if chain then _(obj).chain() else obj


# A method to easily add functions to the OOP wrapper.
addToWrapper = (name, func) ->
  wrapper.prototype[name] = ->
    args = So.util.toArray arguments
    unshift.call args, this._wrapped
    result func.apply(_, args), this._chain


# Add all ofthe Social functions to the wrapper object.
So.util.mixin _


# Add all mutator Array functions to the wrapper.
So.util.each ['pop', 'push', 'reverse', 'shift', 'sort', 'splice', 'unshift'], (name) ->
  method = Array.prototype[name]
  wrapper.prototype[name] = ->
    method.apply(this._wrapped, arguments)
    result(this._wrapped, this._chain)


# Add all accessor Array functions to the wrapper.
So.util.each ['concat', 'join', 'slice'], (name) ->
  method = Array.prototype[name]
  wrapper.prototype[name] = ->
    result(method.apply(this._wrapped, arguments), this._chain)


# Start chaining a wrapped Social object.
wrapper::chain = ->
  this._chain = true
  this


# Extracts the result from a wrapped and chained object.
wrapper::value = -> this._wrapped
