request = require 'request'
Q = require 'q'

SlackMessenger = {
  notify: (message)->
    defered = Q.defer()

    url = config.get('slack.webhook_url')

    reqOpts = options = {
      uri: url,
      method: 'POST',
      json: {
        text: message
      }
    }

    request reqOpts, (e, res, body)->
      console.log body
      return defered.reject "Invalid status." unless res.statusCode is 200
      return defered.reject e if e?

      defered.resolve(true)

    return defered.promise
}

module.exports = SlackMessenger