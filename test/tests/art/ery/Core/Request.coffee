{log, formattedInspect, merge} = require 'art-foundation'
{Request, Pipeline} = Neptune.Art.Ery

module.exports = suite:
  props: ->
    test "new Request key and data set via props:", ->

      assert.selectedPropsEq
        # via getters
        key:    "123"
        data:   "abc"
        props:  props = key: "123", data: "abc"

        new Request
          type:   "get"
          props:
            key:    "123"
            data:   "abc"
          session:  {}
          pipeline: new Pipeline

    test "new Request props: myProp: 987", ->

      assert.selectedPropsEq
        # via getters
        key:    undefined
        data:   undefined
        props:  myProp: 987

        new Request
          type:     "get"
          props:    myProp: 987
          session:  {}
          pipeline: new Pipeline

    test "new Request key: and data: are merged into props:", ->

      assert.selectedPropsEq
        # via getters
        key:    "123"
        data:   "abc"
        props:  props = key: "123", data: "abc", customProp: "xyz"

        # direct reads
        _key:   undefined
        _data:  undefined
        _props: props

        new Request
          type:   "get"
          key:    "123"
          data:   "abc"
          props:  customProp: "xyz"
          session:  {}
          pipeline: new Pipeline

  validation: ->
    test "new Request - invalid", ->
      assert.throws -> new Request

    test "new Request - missing session", ->
      assert.throws ->
        new Request
          type: "get"
          key: "123"
          pipeline: new Pipeline


    test "new Request type: 'get' - valid", ->
      new Request
        type: "get"
        key: "123"
        pipeline: new Pipeline
        session: {}

    test "inspectedObjects new Request", ->
      request = new Request
        type:     "get"
        key:      "123"
        pipeline: new Pipeline
        session:  {}

      assert.selectedPropsEq
        type:             "get"
        props:            key: "123"
        session:          {}
        subrequestCount:  0
        request.inspectedObjects["Neptune.Art.Ery.Request"]

    test "new Request type: 'create' - valid", ->
      new Request
        type: "create"
        pipeline: new Pipeline
        session: {}
        data: {}

    test "new Request type: 'update' - valid", ->
      new Request
        type: "update"
        key: "123"
        pipeline: new Pipeline
        session: {}
        data: {}

    test "new Request type: 'delete' - valid", ->
      new Request
        type: "delete"
        key: "123"
        pipeline: new Pipeline
        session: {}

  properties: ->
    test "getKey", ->
      request = new Request
        type: "get"
        pipeline: new Pipeline
        session: {}
        props: key: "123"
      assert.eq request.getKey(), "123"

    test "getRequestType alias for getType", ->
      request = new Request
        type: "get"
        pipeline: new Pipeline
        session: {}
      assert.eq request.getRequestType(), "get"
      assert.eq request.getType(), "get"

  withData: ->
    test "withData", ->
      request = new Request
        type: "create"
        pipeline: new Pipeline
        session: {}
        data: {}
      request.withData foo: "bar"
      .then (newRequest) ->
        assert.neq newRequest, request
        assert.eq newRequest.data, foo: "bar"

    test "withMergedData", ->
      request = new Request
        type: "create"
        pipeline: new Pipeline
        session: {}
        data: bing: "bong"
      request.withMergedData foo: "bar"
      .then (newRequest) ->
        assert.neq newRequest, request
        assert.eq newRequest.data, bing: "bong", foo: "bar"

  derivedRequestsPersistProps: ->
    test "originatedOnServer", ->
      request = new Request
        type: "get"
        key: "123"
        originatedOnServer: true
        pipeline: new Pipeline
        session: {}

      request.withData({}).then (derivedRequest) ->
        assert.selectedPropsEq
          originatedOnServer: true
          type:     "get"
          key:      "123"
          pipeline: request.pipeline
          derivedRequest

  remoteRequestProps: ->
    newRequest = (options) ->
      new Request merge
        pipeline: new Pipeline, session: {}
        options

    test "create", ->
      assert.eq
        method: "post"
        url:    "/api/pipeline"
        data:   data: myField: "myInitialValue"
        newRequest(type: "create", data: myField: "myInitialValue").remoteRequestProps

    test "get", ->
      assert.eq
        method: "get"
        url:    "/api/pipeline/myKey"
        data:   null
        newRequest(type: "get", key: "myKey").remoteRequestProps

    test "get with compound key", ->
      assert.eq
        method: "get"
        url:    "/api/pipeline"
        data:   data: userId: "abc", postId: "xyz"
        newRequest(type: "get", data: userId: "abc", postId: "xyz").remoteRequestProps

    test "delete", ->
      assert.eq
        method: "delete"
        url:    "/api/pipeline/myKey"
        data:   null
        newRequest(type: "delete", key: "myKey").remoteRequestProps

    test "update", ->
      assert.eq
        method: "put"
        url:    "/api/pipeline/myKey"
        data:   data: myField: "myNewValue"
        newRequest(type: "update", key: "myKey", data: myField: "myNewValue").remoteRequestProps

    test "update myAdd: 1", ->
      assert.eq
        method: "put"
        url:    "/api/pipeline/myKey"
        data:   myAdd: myCount: 1
        newRequest(type: "update", key: "myKey", props: myAdd: myCount: 1).remoteRequestProps