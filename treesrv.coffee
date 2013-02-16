http = require('http')
config = require('./config')
ParsedRequest = require('./request').ParsedRequest

# Used to finish an HTTP response with an error
# Don't include user controlled strings in 'phrase'
respondWithError = (res, code, phrase) ->
  res.writeHead(code, phrase, {"Content-Type": "text/html"})

  res.end("""
    <!DOCTYPE html>
    <head><title>#{phrase}</title></head>
    <body><h1>#{phrase}</h1></body>
  """)

http.createServer((req, res) ->
  # We only understand GET and HEAD
  unless req.method in ['GET', 'HEAD']
    respondWithError(res, 400, 'Bad Request')
    return

  # Try to parse the request
  parsedRequest = new ParsedRequest(config, req)

  unless parsedRequest.tree? and parsedRequest.path?
    # Didn't work
    respondWithError(res, 404, 'Not Found')
    return

  res.writeHead(200, {
    "Content-Type": "text/plain"
  })

  res.end("Hello, world")
).listen(config.http.port, config.http.bind_address)
