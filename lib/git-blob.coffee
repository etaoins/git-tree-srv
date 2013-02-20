gitUtil = require('./git-util')

# Map treeSha1:pathname to size in bytes
# This should be immutable so we can use it to skip a Git command without
# risking stale data. Attackers can only expand this cache using legitimate
# SHA-1/pathname pairs so the size is naturally limited
blobSizeCache = {}

cachingBlobSizeQuery = (repo, treeSha1, pathname, callback) ->
  blobRef = "#{treeSha1}:#{pathname}"

  if blobSizeCache[blobRef]?
    # We have this size cached
    callback(blobSizeCache[blobRef])
  else
    # Ask Git for the blob size
    gitUtil.gitOutput(repo, 'cat-file', ['-s', blobRef], (size) ->
      if size?
        blobSizeCache[blobRef] = size

      callback(size)
    )

query = (repo, tree, pathname, callback) ->
  blobInfo = {}

  # Parse the revision
  gitUtil.gitOutput(repo, 'rev-parse', ['--verify', tree], (treeSha1) ->
    unless treeSha1?
      # Failed to parse the ref
      callback(null)
      return

    # Is this a symbolic ref?
    isSymbolicRef = treeSha1.indexOf(tree) != 0

    # Find out the file size
    cachingBlobSizeQuery(repo, treeSha1, pathname, (size) ->
      unless size?
        callback(null)
        return

      callback(treeSha1: treeSha1, isSymbolicRef: isSymbolicRef, size: size)
    )
  )

cat = (repo, treeSha1, pathname) ->
  gitUtil.spawnGit(repo, 'cat-file', ['-p', "#{treeSha1}:#{pathname}"])
 
module.exports.query = query
module.exports.cat = cat
