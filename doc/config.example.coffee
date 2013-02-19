# This example is CoffeeScript so indentation is significant
# Please indent using two spaces
config =
  http:
    # Listen on port 8080
    port: 8080
    # Accept connections only from localhost
    # Change to 0.0.0.0 to allow connections from anywhere
    bind_address: '127.0.0.1'

  # See http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9 for a description of the Cache-Control header
  cache_control:
    # Allow the client to cache SHA-1 referenced trees for 1 year
    # This is safe because the SHA-1 hash means the tree is cryptographically guaranteed to be the same
    sha1: 'public, max-age=31556926'
    # Make the client revalidate symbolically referenced (HEAD, branch, or tag name) trees on every request
    # An ETag will be generated based on the actual tree SHA-1 so a redownload won't be required if the symbolic
    # reference hasn't changed.
    symbolic: 'public, must-revalidate'

  repos:
    # HTTP root path for the repo
    # Use "/" to map all requests to this repo
    # Otherwise surround a name with / to make it appear as a top-level subdirectory
    "/project1/":
      # The filesystem path to the repository's git directory
      # For bare repositories this should point to the root directory of repository
      # For checkouts with working trees this should point to the .git subdirectory
      git_dir: "/Users/bob/Code/project1/.git"
      # Optional path offset in to the repository
      # This is useful for limiting access or making shorter URLs
      #subdir: "www/static/"

module.exports = config
