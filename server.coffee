http = require('http')
mime = require('mime')
git_blob = require('./lib/git-blob')

ParsedRequest = require('./lib/request').ParsedRequest

# Make sure we have the right number of args
if process.argv.length != 3
  console.error("Usage: git-tree-srv config_File\n")
  console.error("See doc/config.coffee.example in the git-tree-srv package for more information")
  process.exit(1)

configFile = process.argv[2]

try
  config = require('./' + configFile)
catch e
  config = require(configFile)

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
    
    # We only understand GET and HEAD
    unless req.method in ['GET', 'HEAD']
      res.writeHead(405, 'Method Not Allowed',
        "Content-Length": 0
        "Allow": "GET, HEAD"
      )
      res.end()
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

    # HTTP responses are stream-like so we can pipe right to them
    blobCat.stdout.pipe(res)

    blobCat.stdout.on('close', ->
      # The response is finished
      res.end()
    )
    
    res.on('close', ->
      # Remote end hung up - we can stop the cat
      # disconnect is more friendly but it doesn't exist on Node 0.6
      (blobCat.disconnect || blobCat.kill)()
    )
  )

).listen(config.http.port, config.http.bind_address)

console.log("Listening on #{config.http.bind_address}:#{config.http.port}")
