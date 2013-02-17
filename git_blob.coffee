child_process = require('child_process')

# Map treeSha1:pathname to size in bytes
# This should be immutable so we can use it to skip a Git command without
# risking stale data. Attackers can only expand this cache using legitimate
# SHA-1/pathname pairs so the size is naturally limited
blobSizeCache = {}

gitArgs = (repo, subcommand, cmdArgs = []) ->
  ["--git-dir=#{repo.git_dir}", subcommand].concat(cmdArgs)

# Spawns Git and returns the process
spawnGit = (repo, subcommand, cmdArgs = []) ->
  gitProcess = child_process.spawn('git', gitArgs(repo, subcommand, cmdArgs))

  # Dump any badness to the console
  gitProcess.stderr.on('data', (data) ->
    console.warn("git: #{data}")
  )

  gitProcess

# Execs Git and invokes the callback with the contents of stdout on success
# or null on error
gitOutput = (repo, subcommand, cmdArgs, callback) ->
  args = gitArgs(repo, subcommand, cmdArgs)

  child_process.execFile('git', args, {}, (error, stdout, stderr) ->
    unless error?
      # Trim off the newline
      callback(stdout.trimRight())
    else
      console.warn("git: #{stderr}")
      callback(null)
  )

cachingBlobSizeQuery = (repo, treeSha1, pathname, callback) ->
  blobRef = "#{treeSha1}:#{pathname}"

  if blobSizeCache[blobRef]?
    # We have this size cached
    callback(blobSizeCache[blobRef])
  else
    # Ask Git for the blob size
    gitOutput(repo, 'cat-file', ['-s', blobRef], (size) ->
      if size?
        blobSizeCache[blobRef] = size

      callback(size)
    )

query = (repo, tree, pathname, callback) ->
  blobInfo = {}

  # Parse the revision
  gitOutput(repo, 'rev-parse', ['--verify', tree], (treeSha1) ->
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
  spawnGit(repo, 'cat-file', ['-p', "#{treeSha1}:#{pathname}"])
 
module.exports.query = query
module.exports.cat = cat
