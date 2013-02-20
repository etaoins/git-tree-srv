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

module.exports.spawnGit = spawnGit
module.exports.gitOutput = gitOutput
