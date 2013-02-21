gitUtil = require './git-util'

# Map of treeSha1:pathname to size in bytes
# This should be immutable so we can use it to skip a Git command without
# risking stale data. Attackers can only expand this cache using legitimate
# SHA-1/pathname pairs so the size is naturally limited
blobSizeCache = {}

# Queries the size of a blob and caches it forever
queryBlobSize = (repo, treeSha1, pathname, callback) ->
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

# Queries the size and tree SHA-1 for a tree revision and pathname
query = (repo, tree, pathname, callback) ->
  blobInfo = {}

  # Parse the revision
  gitUtil.parseRevision(repo, tree).once 'finish', (treeSha1) ->
    unless treeSha1?
      # Failed to parse the ref
      callback(null)
      return

    # Is this a symbolic ref?
    isSymbolicRef = treeSha1.indexOf(tree) != 0

    # Find out the file size
    queryBlobSize(repo, treeSha1, pathname, (size) ->
      unless size?
        callback(null)
        return

      callback(treeSha1: treeSha1, isSymbolicRef: isSymbolicRef, size: size)
    )

# Returns a ChildProcess instance with stdout streaming the requested file
cat = (repo, treeSha1, pathname) ->
  gitUtil.spawnGit(repo, 'cat-file', ['-p', "#{treeSha1}:#{pathname}"])
 
module.exports.query = query
module.exports.cat = cat
