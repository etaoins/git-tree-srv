url = require('url')

# Captures the tree and repo path from a request path
treePathRegexp = /^([^\/]+)\/(.+)$/

class ParsedRequest
  @repo = null
  @httpRoot = null
  @tree = null
  @path = null

  constructor: (config, nodeReq) ->
    # Ignore the query
    fullPath = url.parse(nodeReq.url).pathname

    # Find the repo we're requesting
    for httpRoot, repo of config.repos
      # Don't do this in the regexp because escaping is annoying
      if fullPath.indexOf(httpRoot) == 0
        @repo = repo
        @httpRoot = httpRoot
        break

    unless @repo?
      # Didn't find a matching repo
      return

    # Parse the remaining URL components
    decodedPath = decodeURIComponent(fullPath[(@httpRoot.length)..])
    treeAndPath = treePathRegexp.exec(decodedPath)

    [unused, @tree, @path] = treeAndPath if treeAndPath

module.exports.ParsedRequest = ParsedRequest
