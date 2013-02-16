http = require('http')
mime = require('mime')
config = require('./config')
git_blob = require('./git_blob')

ParsedRequest = require('./request').ParsedRequest

# Used to finish an HTTP response with an error
# Don't include user controlled strings in 'phrase'
finishWithError = (res, code, phrase) ->
  res.writeHead(code, phrase, {"Content-Type": "text/html"})

  res.end("""
    <!DOCTYPE html>
    <head><title>#{phrase}</title></head>
    <body><h1>#{phrase}</h1></body>
  """)

http.createServer((req, res) ->
  # We only understand GET and HEAD
  unless req.method in ['GET', 'HEAD']
    finishWithError(res, 400, 'Bad Request')
    return

  # Try to parse the request
  parsedReq = new ParsedRequest(config, req)

  unless parsedReq.tree? and parsedReq.path?
    # Didn't work
    finishWithError(res, 404, 'Not Found')
    return

  git_blob.query(parsedReq.repo, parsedReq.tree, parsedReq.path, (blobInfo) ->
    unless blobInfo?
      finishWithError(res, 404, 'Not Found')
      return

    cacheControl = if blobInfo.isSymbolic
      config.cache_control.symbolic
    else
      config.cache_control.sha1

    # We have enough metadata
    res.writeHead(200,
      "Content-Length": blobInfo.size
      "ETag": '"' + blobInfo.treeSha1 + '"'
      "Cache-Control": cacheControl
      "Content-Type": mime.lookup(parsedReq.path)
    )

    # Pipe the git cat-file output right to the HTTP response
    blobCat = git_blob.cat(parsedReq.repo, blobInfo.treeSha1, parsedReq.path)

    blobCat.stdout.on('data', (data) ->
      res.write(data)
    )

    blobCat.on('exit', ->
      blobCat.stdout.end()
      res.end()
    )
  )

).listen(config.http.port, config.http.bind_address)
