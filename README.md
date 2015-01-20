[Halcyon](https://halcyon.sh/)
==============================

Halcyon is a system for installing [Haskell](https://haskell.org/) apps and development tools, including [GHC](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/) and [Cabal](https://www.haskell.org/cabal/users-guide/).

See the [Halcyon website](https://halcyon.sh/) for more information.


Usage
-----

The `halcyon install` command can be used instead of `cabal install`:

```
$ halcyon install https://github.com/mietek/halcyon-tutorial
```


### Installation

Halcyon can be installed by cloning the [_git_ repository](https://github.com/mietek/halcyon), or by running the [setup script](https://github.com/mietek/halcyon/blob/master/setup.sh), which also installs the necessary OS packages and sets up the environment:

```
$ source <( curl -sL https://github.com/mietek/halcyon/raw/master/setup.sh )
```


### Documentation

- Start with the [Halcyon tutorial](/tutorial/) to learn how to deploy a simple Haskell web app using Halcyon.

- See the [Halcyon reference](/reference/) for a complete list of the available commands and options.


#### Internals

Halcyon is written in [GNU _bash_](https://gnu.org/software/bash/), using the [_bashmenot_](https://bashmenot.mietek.io/) library.

- Dive into the [Halcyon source code](https://github.com/mietek/halcyon) to understand how it all works.


About
-----

Made by [Miëtek Bak](https://mietek.io/).  Published under the [MIT X11 license](https://halcyon.sh/license/).
