# Spawns Git and returns the process
spawnGit = (repo, subcommand, args = []) ->
  # Run the subcommand pointed at the right repo
  args = ["--git-dir=#{repo.git_dir}", subcommand].concat(args)
  gitProcess = require('child_process').spawn('git', args)

  # Dump any badness to the console
  gitProcess.stderr.on('data', (data) ->
    console.warn("git: #{data}")
  )

  gitProcess

# Spawns Git and invokes the callback with the contents of stdout on success
# or null on error
gitOutput = (repo, subcommand, args, callback) ->
  output = ''

  gitProcess = spawnGit(repo, subcommand, args)
  gitProcess.stdout.on('data', (data) -> output += data)

  gitProcess.on('exit', (code) ->
    if code == 0
      # Flush stdout
      gitProcess.stdout.end()

      # Success - cut off the trailing whitespace
      callback(output.trimRight())
    else
      # Failure
      callback(null)
  )

query = (repo, tree, path, callback) ->
  blobInfo = {}

  # Parse the revision
  gitOutput(repo, 'rev-parse', ['--verify', tree], (treeSha1) ->
    unless treeSha1?
      # Failed to parse the ref
      callback(null)
      return

    # Is this symbolic?
    isSymbolic = treeSha1.indexOf(tree) != 0

    # Find out the file size
    gitOutput(repo, 'cat-file', ['-s', "#{treeSha1}:#{path}"], (size) ->
      unless size?
        callback(null)
        return

      callback(treeSha1: treeSha1, isSymbolic: isSymbolic, size: size)
    )
  )

cat = (repo, treeSha1, path) ->
  spawnGit(repo, 'cat-file', ['-p', "#{treeSha1}:#{path}"])
 
module.exports.query = query
module.exports.cat = cat
