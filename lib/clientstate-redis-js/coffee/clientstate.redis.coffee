class ClientState

  constructor: (@address, @clientid) ->
    # user gave us github app secret/id on the server
    # we set them up a redis with an oauth endpoint
    # for local testing @address might be:
    #     "http://localhost:3000"
    # and @clientid might be
    #     b6d50cdc7d9372561081
    #git
    # this will be populated after successful github redirect
    # TODO - cache in localStorage
    #@access_token = getParams()["access_token"] # or localStorage

  auth_popup: () ->
    if arguments.length is 0
      provider = "github"
      cb = (provider_data) ->
        console.log provider_data
    if arguments.length is 1
      provider = "github"
      cb = arguments[0]
    if arguments.length is 2
      [provider, cb] = arguments
    OAuth.initialize @clientid
    OAuth.setOAuthdURL @address
    self = this
    OAuth.popup provider, (err, provider_data) ->
      if err?
        console.log err.stack
      self.access_token = provider_data.access_token
      cb provider_data
    return


class ClientStateRedis extends ClientState
  get: () ->
    if arguments.length is 3
      [command, key, cb] = arguments
    if arguments.length is 4
      [command, key, args, cb] = arguments
    url = "#{@address}/#{command}/#{key}?access_token=#{@access_token}&jsonp"
    if args isnt undefined
      # args must be an array
      url += "&args=#{args.join ','}"
    console.log url, cb
    JSONP url, cb

  post: () ->
    # must supply callback as last arg
    if arguments.length is 5
      [command, key, value, args, cb] = arguments
    if arguments.length is 4
      [command, key, value, cb] = arguments
    request = new XMLHttpRequest()
    params = "action=something"
    url = "#{@address}/#{command}/#{key}?access_token=#{@access_token}"
    if args isnt undefined
      url += "&args=#{args.join ','}"
    request.open 'POST', url, true
    request.onreadystatechange = (a, b, c) ->
      if request.readyState is 4
        cb()
    request.send value

window.ClientStateRedis = ClientStateRedis
