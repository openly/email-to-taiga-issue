Q = require 'q'
restify = require 'restify'

class TaigaConn
  constructor: ()->
    @APIBase = "https://api.taiga.io"
    @RESTClient = restify.createJsonClient({
      url: @APIBase
    });

  login: ()->
    defered = Q.defer()

    authSettings = config.get("taiga.auth")

    authSettings.type = "normal"

    @RESTClient.post('/api/v1/auth', authSettings, (e, req, res, obj)->
      
      return defered.reject e if e?
      defered.resolve obj
    )

    return defered.promise

  getProject: (authToken, slug)->
    defered = Q.defer()

    reqOpts = {
      path: "/api/v1/projects/by_slug?slug=#{slug}",
      headers: {
        "Authorization" : "Bearer #{authToken}"
      }
    }

    @RESTClient.get(reqOpts,(e,req, res, obj)->
      return defered.reject e if e?
      defered.resolve obj  
    )

    return defered.promise

  createIssue: (authToken, args)->
    defered = Q.defer()

    reqOpts = {
      path: "/api/v1/issues",
      headers: {
        "Authorization" : "Bearer #{authToken}"
      }
    }

    @RESTClient.post(reqOpts, args,(e, req, res, obj)->
      return defered.reject e if e?
      defered.resolve obj  
    )

    return defered.promise

module.exports = TaigaConn