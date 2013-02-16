http = require('http')
mime = require('mime')
config = require('./config')
git_blob = require('./git_blob')

ParsedRequest = require('./request').ParsedRequest

# Used to finish an HTTP response with an error
# Don't include user controlled strings in 'phrase'
finishWithError = (res, code, phrase) ->
  errorDoc = """
    <!DOCTYPE html>
    <head><title>#{phrase}</title></head>
    <body><h1>#{phrase}</h1></body>
  """

  res.writeHead(code, phrase,
    "Content-Type": "text/html"
    "Content-Length": errorDoc.length
  )

  res.end(errorDoc)

http.createServer((req, res) ->
  # We only understand GET and HEAD
  unless req.method in ['GET', 'HEAD']
    finishWithError(res, 400, 'Bad Request')
    return

  # Try to parse the request
  parsedReq = new ParsedRequest(config, req)

  unless parsedReq.tree? and parsedReq.pathname?
    # Didn't work
    finishWithError(res, 404, 'Not Found')
    return

  git_blob.query(parsedReq.repo, parsedReq.tree, parsedReq.pathname, (blobInfo) ->
    unless blobInfo?
      finishWithError(res, 404, 'Not Found')
      return

    # Use the tree SHA-1 as the ETag 
    # The tree SHA-1 recursively includes the blob's SHA1 which means this ETag
    # is guaranteed to be stable
    etag = '"' + blobInfo.treeSha1 + '"'

    if req.headers['if-none-match'] == etag
      # The file is the same version the client has
      res.writeHead(304,
        "ETag": etag
      )

      res.end()
      return

    # Send different caching headers for symbolic refs
    cacheControl = if blobInfo.isSymbolicRef
      config.cache_control.symbolic
    else
      config.cache_control.sha1

    # We have enough metadata
    res.writeHead(200,
      "Content-Length": blobInfo.size
      "ETag": etag
      "Cache-Control": cacheControl
      "Content-Type": mime.lookup(parsedReq.pathname)
    )

    # The client doen't want the body
    if req.method is 'HEAD'
      res.end()
      return

    # Pipe the git cat-file output right to the HTTP response
    blobCat = git_blob.cat(parsedReq.repo, blobInfo.treeSha1, parsedReq.pathname)

    blobCat.stdout.on('data', (data) ->
      res.write(data)
    )

    blobCat.on('exit', ->
      blobCat.stdout.end()
      res.end()
    )
  )

).listen(config.http.port, config.http.bind_address)
