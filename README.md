[Halcyon](http://halcyon.sh/)
=============================

Halcyon is a system for fast and reliable deployment of Haskell applications, used by [_Haskell on Heroku_](http://haskellonheroku.com/).

**This page describes version 1.0, which is currently undergoing testing.  Check back soon, or follow [@mietek](http://twitter.com/mietek).**


Examples
--------

_Coming soon._


Usage
-----

```
$ halcyon deploy
```

To learn more, see the [full list of examples](http://halcyon.sh/examples/), and continue with the [user’s guide](http://halcyon.sh/guide/).

Interested in deploying Haskell web applications?  Try [_Haskell on Heroku_](http://haskellonheroku.com/).


### Installation

Clone the Halcyon repository:

```
$ git clone https://github.com/mietek/halcyon ANY_DIR/halcyon
```

Set up paths:

```
$ export PATH=ANY_DIR/halcyon:$PATH
$ source <( halcyon show-paths )
```


### Dependencies

Currently, Halcyon supports:

- Ubuntu [10.04 LTS](http://releases.ubuntu.com/10.04/), [12.04 LTS](http://releases.ubuntu.com/12.04/), and [14.04 LTS](http://releases.ubuntu.com/14.04/) (64-bit)
- GHC [7.6.1](http://www.haskell.org/ghc/download_ghc_7_6_1), [7.6.3](http://www.haskell.org/ghc/download_ghc_7_6_3), [7.8.2](http://www.haskell.org/ghc/download_ghc_7_8_2), and [7.8.3](http://www.haskell.org/ghc/download_ghc_7_8_3)
- _cabal-install_ [1.20.0.0](http://www.haskell.org/cabal/download.html) and newer

Halcyon requires:

- [GNU _bash_](http://gnu.org/software/bash/) 4 or newer
- [GNU _date_](http://gnu.org/software/coreutils/manual/html_node/date-invocation.html)
- [GNU _sort_](http://gnu.org/software/coreutils/manual/html_node/sort-invocation.html)
- [_curl_](http://curl.haxx.se/)
- [OpenSSL](https://www.openssl.org/)
- [_bashmenot_](http://bashmenot.mietek.io/)


### Internals

For an in-depth discussion of Halcyon internals, see the [programmer’s reference](http://halcyon.sh/reference/).

Halcyon is built with [_bashmenot_](http://bashmenot.mietek.io/), a library of functions for safer shell scripting in [GNU _bash_](http://gnu.org/software/bash/).

Additional information is available in the [_bashmenot_ programmer’s reference](http://bashmenot.mietek.io/reference/).


### Bugs

Please report any problems with Halcyon on the [issue tracker](https://github.com/mietek/halcyon/issues/).

There is a [separate issue tracker](https://github.com/mietek/halcyon-website/issues/) for problems with the documentation.


About
-----

My name is [Miëtek Bak](http://mietek.io/).  I make software, and Halcyon is one of [my projects](http://mietek.io/projects/).

This work is published under the [MIT X11 license](http://halcyon.sh/license/), and supported by my company, [Least Fixed](http://leastfixed.com/).

Would you like to work with me?  Say [hello](http://mietek.io/).


### Acknowledgments

Thanks to [CircuitHub](https://circuithub.com/), [Tweag I/O](http://www.tweag.io/), and [Purely Agile](http://purelyagile.com/) for advice and assistance.
