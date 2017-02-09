Foundation = require 'art-foundation'
Request = require './Request'
Response = require './Response'
{config} = require './Config'

{toPlainObjects, toInspectedObjects, getInspectedObjects, defineModule, BaseObject, Promise, log, isPlainObject, mergeInto, merge, shallowClone, CommunicationStatus} = Foundation
{success, failure} = CommunicationStatus

###
TODO

Filters should be able to detect if they are being run server-side or client-side.
  This is a simple global value, since the entire code-base is either running in Node or in the Browser.
  It doesn't change at runtime - duh!
  So, I think we should have a value like: Art.Ery.location, which is set at init-time
  to the code-base's running location.

  WHY do we need this? Filters may want to run on both AND run a little differently on both.

    LinkFieldsFilter, for example, would translate a linked field {foo: id: 123} to {fooId: 123} and not need
    to transmit the whole foo-record over the wire. BUT, if the data was {foo: username: "hi"}, that indicates
    a new foo-record should be created, and that should be done server-side.

    IT's a little thing right now, so I'm not implementing it... yet

  WHY PART 2

    This may be the solution to Filters which are not symmetrical. It's possible the before-part should be
    client-side-only, but the after-part should be server-side-only (for example).

    We could add @beforeLocation and @afterLocation props, but maybe this one solution is "good enough" for everything.
    The only down-side is it isn't as clear in the ArtEry-Pipeline report, but that may be OK since it doesn't seem like
    it'll be used that much.

Art.Ery.location values:
  "server"
  "client"
  "both" - this is the "serverless" mode, it's all run client-side, but it includes both client-side and server-side filters.

SBD: Just realized that location == "client" still means "server" for server-side subrequests.
  Maybe 'client' should be 'requester' instead of 'client'?
  'requester' and 'server'?
###

defineModule module, class Filter extends require './ArtEryBaseObject'
  @_location: "server" # 'server', 'client' or 'both'
  @location: (@_location) ->

  ################
  # class inheritable props
  ################
  @extendableProperty
    beforeFilters: {}
    afterFilters: {}
    fields: {}

  ############################
  # Class Declaration API
  ############################
  @fields: @extendFields

  ###
  IN: requestType, requestFilter
  IN: map from requestTypes to requestFilters

  requestFilter: (request) ->
    IN: Request instance
    OUT: return a Promise returning one of the list below OR just return one of the list below:
      Request instance
      Response instance
      anythingElse -> toResponse anythingElse

    To reject a request:
    - throw an error
    - return a rejected promise
    - or create a Response object with the appropriate fields
  ###
  @before: (a, b) -> @extendBeforeFilters a, b if a
  before: (a, b) -> @extendBeforeFilters a, b if a

  ###
  IN: requestType, responseFilter
  IN: map from requestTypes to responseFilter

  responseFilter: (response) ->
    IN: Response instance
    OUT: return a Promise returning one of the list below OR just return one of the list below:
      Response instance
      anythingElse -> toResponse anythingElse

    To reject a request:
    - throw an error
    - return a rejected promise
    - or create a Response object with the appropriate fields
  ###
  @after: (a, b) -> @extendAfterFilters a, b if a
  after: (a, b) -> @extendAfterFilters a, b if a

  #################################
  # class instance methods
  #################################

  constructor: (options = {}) ->
    super
    {@serverSideOnly, @location, @clientSideOnly, @name, fields} = options
    @name ||= @class.getName()
    @_location ||= @class._location || "server"
    @shouldFilter()
    @extendFields fields if fields
    @after options.after
    @before options.before

  @property "name"
  @property "location"

  shouldFilter: (processingLocation) ->
    switch @location
      when "server" then processingLocation != "client"
      when "client" then processingLocation != "server"
      when "both" then true
      else throw new Error "Filter #{@getName()}: invalid filter location: #{@location}"

  toString: -> @getName()

  getBeforeFilterForRequest: ({requestType, location}) -> @shouldFilter(location) && (@beforeFilters[requestType] || @beforeFilters.all)
  getAfterFilterForRequest:  ({requestType, location}) -> @shouldFilter(location) && (@afterFilters[requestType]  || @afterFilters.all)

  processBefore:  (request) -> @_processFilter request, @getBeforeFilterForRequest request
  processAfter:   (request) -> @_processFilter request, @getAfterFilterForRequest  request

  @getter
    inspectedObjects: ->
      "#{@getNamespacePath()}(#{@name})":
        toInspectedObjects @props

    props: ->
      {
        @location
      }

  ###
  OUT:
    promise.then (request or response) ->
      NOTE: response may be failing
    .catch -> internal errors only
  ###
  _processFilter: (requestOrResponse, filterFunction) ->

    requestOrResponse.next Promise.then =>
      if filterFunction
        requestOrResponse.addFilterLog @
        filterFunction.call @, requestOrResponse
      else
        # pass-through if no filter
        requestOrResponse
