# Overview

git-tree-srv is a simple HTTP server for hosting static files from a [Git](http://www.git-scm.com) tree at a specific revision.

# Setup

git-tree-srv is a [Node.js](http://nodejs.org) application intended to be installed with [npm](https://npmjs.org). To install run:

	npm install -g git://github.com/etaoins/git-tree-srv

Before running git-tree-srv a configuration file must be created. See [config.example.coffee](doc/config.example.coffee) for an example configuration file. JavaScript configuration files are also accepted as long as the structure of the file is preserved.

In Unix-like environments you can run `git-tree-srv [config file]` if npm's `bin` directory is in your path. On Windows `git-tree-srv` can be invoked from [msysgit](http://msysgit.github.com)'s bash prompt.

# Usage

Files from the Git repository can be accessed as http://hostname:port/reponame/revision/path/to/file where:

* *hostname* is the hostname of the server running git-tree-src
* *port* is the configured value of `http.port`
* *reponame* is the HTTP root path for the repository as configured in the `repos` section
* *revision* is a [Git revision](http://www.kernel.org/pub/software/scm/git/docs/gitrevisions.html). Examples include branch names, tags, tree SHA-1s, and "HEAD". If the revision contains a `/` character (e.g. `origin/master`) it must be [percent encoded](http://en.wikipedia.org/wiki/Percent-encoding) as `%2f`
* *path/to/file* is the path to the file in the Git repository. If the `subdir` configuration option for the repo is used this path is relative to `subdir`

Parts of the URL after a `?` character are ignored to allow static web applications to safely pass data via query strings. To reference a repository path containing a literal `?` character percent encode it as `%3f`.

The Git working tree and index are never used. This means it is safe to edit files, stage changes for commit, etc. without interfering with git-tree-srv. Any committed changes will take immediate effect on the server side without a restart.

By default browsers can cache files served from an explicit tree SHA-1 for 1 year but must revalidate all other files on every request. This can be changed in the `cache_control` configuration section. This can also be used to implement server-side caching in combination with a caching [reverse HTTP proxy](http://en.wikipedia.org/wiki/Reverse_proxy) such as [Nginx](http://nginx.org/en).

# Known Issues and Limitations

* HTTPS, compression, authentication and URL rewriting are not supported. A reverse proxy such as [Nginx](http://nginx.org/en/) or [Varnish](https://www.varnish-cache.org) should be used if that functionality is desired.
* Up to three `git` processes are spawned for each request. For platforms with heavyweight process creation (such as Windows) this can cause poor performance. On Mac OS X the default process ulimit is very low and can cause git-tree-srv to crash if it receives too many concurrent requests.
