[Halcyon](https://halcyon.sh/)
==============================

Halcyon is a system for deploying Haskell applications, used by [Haskell on Heroku](https://haskellonheroku.com/).


Overview
--------

Halcyon can deploy any Haskell application with a single command, using the appropriate versions of GHC, Haskell and non-Haskell libraries, and Haskell build tools.

Applications can be deployed from local directories, unpacked from Cabal repositories, or cloned from _git_ repositories.  Additional applications can be specified as build-time or runtime dependencies.

Halcyon archives _build byproducts_ in _layers_, with a separate layer for GHC, Cabal, the sandbox, and the application.  The _build products_ are also archived separately, as _slugs_.

Public and private storage can be used to speed up deployment with previously built layer archives.  Moreover, partially-matching sandbox layers can be detected and extended, speeding up builds which share a common subset of dependencies.

The build process is completely customizable, with _hooks_ allowing custom scripts to run before and after the build stage of each layer.  All used hooks are hashed and tracked as explicit dependencies.

Halcyon aims to achieve 100% reproducible build results, while keeping deployment time under 30 seconds.


Usage
-----

Sourcing the output of the `halcyon paths` command sets up the needed `PATH`, `LIBRARY_PATH`, and `LD_LIBRARY_PATH` environment variables, automatically updating Halcyon to the newest version available.

```
$ git clone https://github.com/mietek/halcyon
$ source <( halcyon/halcyon paths )
-----> Auto-updating bashmenot... done, fa1afe1
-----> Auto-updating Halcyon... done, cab00se
```

To disable automatic updates, set [`HALCYON_NO_AUTOUPDATE`](options/#halcyon_no_autoupdate) to `1`.


### Examples

_Work in progress._


### Documentation

- [Command reference](https://halcyon.sh/commands/)
- [Option reference](https://halcyon.sh/options/)
- [Source code](https://github.com/mietek/halcyon/)

Halcyon is built with [_bashmenot_](https://bashmenot.mietek.io/), a library of shell functions for [GNU _bash_](https://gnu.org/software/bash/):

- [_bashmenot_ function reference](https://bashmenot.mietek.io/functions/)
- [_bashmenot_ option reference](https://bashmenot.mietek.io/options/)
- [_bashmenot_ source code](https://github.com/mietek/bashmenot/)


### Dependencies

Halcyon requires [GNU _bash_](https://gnu.org/software/bash/) 4 or newer, and:

- [GNU _date_](https://gnu.org/software/coreutils/manual/html_node/date-invocation.html)
- [GNU _sort_](https://gnu.org/software/coreutils/manual/html_node/sort-invocation.html)
- [_curl_](http://curl.haxx.se/)
- [OpenSSL](https://openssl.org/)
- [_git_](http://git-scm.com/)

Supported platforms and Haskell environments:

- [Ubuntu 14.04 LTS](http://releases.ubuntu.com/14.04/)
- [Ubuntu 12.04 LTS](http://releases.ubuntu.com/12.04/)
- [Ubuntu 10.04 LTS](http://releases.ubuntu.com/10.04/)
- [GHC 7.8.3](https://haskell.org/ghc/download_ghc_7_8_3)
- [GHC 7.6.3](https://haskell.org/ghc/download_ghc_7_6_3)
- [_cabal-install_ 1.20.0.0](https://haskell.org/cabal/download.html) and newer

Versions of GHC including [7.8.2](https://haskell.org/ghc/download_ghc_7_8_2), [7.6.1](https://haskell.org/ghc/download_ghc_7_6_1) , [7.4.2](https://haskell.org/ghc/download_ghc_7_4_2), [7.2.2](https://haskell.org/ghc/download_ghc_7_2_2), and [7.0.4](https://haskell.org/ghc/download_ghc_7_0_4) are also expected to work.  Partial functionality is also available on [OS X](http://www.apple.com/osx/).


### Support

Please report any problems with Halcyon on the [issue tracker](https://github.com/mietek/halcyon/issues/).  There is a [separate issue tracker](https://github.com/mietek/halcyon-website/issues/) for problems with the documentation.

The [#haskell-deployment](irc://chat.freenode.net/haskell-deployment) IRC channel on [freenode](https://freenode.net/) is a good place to ask questions and find answers.


About
-----

My name is [Miëtek Bak](https://mietek.io/).  I make software, and Halcyon is one of [my projects](https://mietek.io/projects/).

This work is published under the [MIT X11 license](https://halcyon.sh/license/), and supported by my company, [Least Fixed](https://leastfixed.com/).

Like my work?  I am available for consulting on software projects.  Say [hello](https://mietek.io/), or follow [@mietek](https://twitter.com/mietek).


### Acknowledgments

Thanks to [CircuitHub](https://circuithub.com/), [Tweag I/O](http://tweag.io/), and [Purely Agile](http://purelyagile.com/) for advice and assistance.
