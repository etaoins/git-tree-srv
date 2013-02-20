EventEmitter = require('events').EventEmitter
child_process = require('child_process')

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

# Parses a given repo and tree revision to a tree SHA-1
parseRevision = do ->
  # Map of running GitRevParse instances indexed by repo:revision
  revParseCommands = {}

  class GitRevParse extends EventEmitter
    constructor: (repo, revision) ->
      gitOutput(repo, 'rev-parse', ['--verify', revision], (sha1) =>
        @emit('finish', sha1)
      )

  return (repo, revision) ->
    key = "#{repo.git_dir}:#{revision}"

    # Only spawn a new GitRevParse if one isn't running
    unless revParseCommands[key]?
      revParse = new GitRevParse(repo, revision)
      revParseCommands[key] = revParse

      # Forget about the GitRevParse once it completes
      revParse.once('finish', ->
        delete revParseCommands[key]
      )

    return revParseCommands[key]


module.exports.spawnGit = spawnGit
module.exports.gitOutput = gitOutput
module.exports.parseRevision = parseRevision
