[Halcyon](http://halcyon.sh/)
=============================

Halcyon is a system for fast and reliable deployment of Haskell applications, used by [Haskell on Heroku](http://haskellonheroku.com/).

**This page describes version 1.0, which is currently undergoing testing.  Check back soon, or follow [@mietek](http://twitter.com/mietek).**


Examples
--------

### “Hello, world!”

- [hello-happstack](https://github.com/mietek/hello-happstack/) ([Live](http://mietek-hello-happstack.herokuapp.com/))
- [hello-mflow](https://github.com/mietek/hello-mflow/) ([Live](http://mietek-hello-mflow.herokuapp.com/))
- [hello-miku](https://github.com/mietek/hello-miku/) ([Live](http://mietek-hello-miku.herokuapp.com/))
- [hello-scotty](https://github.com/mietek/hello-scotty/) ([Live](http://mietek-hello-scotty.herokuapp.com/))
- [hello-simple](https://github.com/mietek/hello-simple/) ([Live](http://mietek-hello-simple.herokuapp.com/))
- [hello-snap](https://github.com/mietek/hello-snap/) ([Live](http://mietek-hello-snap.herokuapp.com/))
- [hello-spock](https://github.com/mietek/hello-spock/) ([Live](http://mietek-hello-spock.herokuapp.com/))
- [hello-wai-warp](https://github.com/mietek/hello-wai-warp/) ([Live](http://mietek-hello-wai-warp.herokuapp.com/))
- [hello-wheb](https://github.com/mietek/hello-wheb/) ([Live](http://mietek-hello-wheb.herokuapp.com/))
- [hello-yesod](https://github.com/mietek/hello-yesod/) ([Live](http://mietek-hello-yesod.herokuapp.com/))


### Real-world

- [gitit](https://github.com/mietek/gitit/) ([Live](http://mietek-gitit.herokuapp.com/))
- [hl](https://github.com/mietek/hl/) ([Live](http://mietek-hl.herokuapp.com/))
- [howistart.org](https://github.com/mietek/howistart.org/) ([Live](http://mietek-howistart.herokuapp.com/))
- [tryhaskell](https://github.com/mietek/tryhaskell/) ([Live](http://mietek-tryhaskell.herokuapp.com/))
- [tryhplay](https://github.com/mietek/tryhplay/) ([Live](http://mietek-tryhplay.herokuapp.com/))
- [tryidris](https://github.com/mietek/tryidris/) ([Live](http://mietek-tryidris.herokuapp.com/))
- [trypurescript](https://github.com/mietek/trypurescript/) ([Live](http://mietek-trypurescript.herokuapp.com/))


Usage
-----

```
$ git clone https://github.com/mietek/halcyon ~/halcyon
$ source <( ~/halcyon/halcyon paths )
$ halcyon deploy
```

Halcyon supports:

- GHC [7.0.4](http://www.haskell.org/ghc/download_ghc_7_0_4), [7.2.2](http://www.haskell.org/ghc/download_ghc_7_2_2), [7.4.2](http://www.haskell.org/ghc/download_ghc_7_4_2), [7.6.1](http://www.haskell.org/ghc/download_ghc_7_6_1), [7.6.3](http://www.haskell.org/ghc/download_ghc_7_6_3), [7.8.2](http://www.haskell.org/ghc/download_ghc_7_8_2), and [7.8.3](http://www.haskell.org/ghc/download_ghc_7_8_3).
- _cabal-install_ [1.20.0.0](http://www.haskell.org/cabal/download.html) and newer.

To learn more, check back soon.


### Dependencies

Halcyon requires:

- Ubuntu [10.04 LTS](http://releases.ubuntu.com/10.04/), [12.04 LTS](http://releases.ubuntu.com/12.04/), [14.04 LTS](http://releases.ubuntu.com/14.04/), or [14.10](http://releases.ubuntu.com/14.10/) (64-bit).
- [GNU _bash_](http://gnu.org/software/bash/) 4 or newer, [GNU _date_](http://gnu.org/software/coreutils/manual/html_node/date-invocation.html), [GNU _sort_](http://gnu.org/software/coreutils/manual/html_node/sort-invocation.html), [_curl_](http://curl.haxx.se/), [OpenSSL](https://www.openssl.org/), and [_git_](http://git-scm.com/).


### Internals

Halcyon is built with [_bashmenot_](http://bashmenot.mietek.io/), a library of functions for safer shell scripting in [GNU _bash_](http://gnu.org/software/bash/).

Additional information is available in the [_bashmenot_ programmer’s reference](http://bashmenot.mietek.io/reference/).


### Bugs

Please report any problems with Halcyon on the [issue tracker](https://github.com/mietek/halcyon/issues/).

There is a [separate issue tracker](https://github.com/mietek/halcyon-website/issues/) for problems with the documentation.


About
-----

My name is [Miëtek Bak](http://mietek.io/).  I make software, and Halcyon is one of [my projects](http://mietek.io/projects/).

This work is published under the [MIT X11 license](http://halcyon.sh/license/), and supported by my company, [Least Fixed](http://leastfixed.com/).

Like my work?  I am available for consulting on software projects.  Say [hello](http://mietek.io/), or follow [@mietek](http://twitter.com/mietek).


### Acknowledgments

Thanks to [CircuitHub](https://circuithub.com/), [Tweag I/O](http://www.tweag.io/), and [Purely Agile](http://purelyagile.com/) for advice and assistance.
