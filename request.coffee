url = require('url')
pathUtil = require('path')

# Captures the tree and repo path from a request path
treePathnameRegexp = /^([^\/]+)\/(.+)$/

class ParsedRequest
  @repo = null
  @httpRoot = null
  @tree = null
  @pathname = null

  constructor: (config, nodeReq) ->
    # Ignore the query
    fullReqPath = url.parse(nodeReq.url).pathname

    # Find the repo we're requesting
    for httpRoot, repo of config.repos
      # Don't do this in the regexp because escaping is annoying
      if fullReqPath.indexOf(httpRoot) == 0
        @repo = repo
        @httpRoot = httpRoot
        break

    unless @repo?
      # Didn't find a matching repo
      return

    # Parse the remaining URL components
    decodedReqPath = decodeURIComponent(fullReqPath[(@httpRoot.length)..])
    treeAndPathname = treePathnameRegexp.exec(decodedReqPath)

    unless treeAndPathname?
      # Didn't match
      return

    [unused, @tree, pathname] = treeAndPathname

    if pathname != pathUtil.normalize(pathname)
      # Don't allow denormalized paths
      return

    if pathname.indexOf("../") == 0
      # Looks like they're requesting above the root
      # This could be used to escape the subdir which would be bad
      return

    if @repo.subdir?
      pathname = pathUtil.join(@repo.subdir, pathname)

    @pathname = pathname

module.exports.ParsedRequest = ParsedRequest
