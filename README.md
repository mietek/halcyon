[Halcyon](http://halcyon.sh/)
=============================

Haskell application deployment.  Used in [Haskell on Heroku](https://haskellonheroku.com/).


Usage
-----

Halcyon is a system for deploying [Haskell](http://haskell.org/) applications rapidly and reliably.

To get started with Halcyon, see the [examples](http://halcyon.sh/), and continue with the [user’s guide](http://halcyon.sh/guide/).

Interested in deploying Haskell web applications?  Try [Haskell on Heroku](http://haskellonheroku.com/).


### Internals

For an in-depth discussion of Halcyon internals, see the [programmer’s reference](http://halcyon.sh/reference/).

Halcyon is built with [_bashmenot_](http://bashmenot.mietek.io/), a library of functions for safer shell scripting in [GNU _bash_](http://gnu.org/software/bash/).

Additional information is available in the [_bashmenot_ programmer’s reference](http://bashmenot.mietek.io/reference/).


### Installation

```
$ git clone https://github.com/mietek/bashmenot.git
$ git clone https://github.com/mietek/halcyon.git
```

Also available as a [Bower](http://bower.io/) package.

```
$ bower install halcyon
```


### Dependencies

Halcyon requires:

- [GNU _bash_](http://gnu.org/software/bash/) 4 or newer
- [GNU _date_](https://www.gnu.org/software/coreutils/manual/html_node/date-invocation.html)
- [GNU _sort_](https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html)
- [_curl_](http://curl.haxx.se/)
- [OpenSSL](https://www.openssl.org/)
- [_bashmenot_](http://bashmenot.mietek.io/)


Support
-------

Please report any problems with Halcyon on the [issue tracker](https://github.com/mietek/halcyon/issues/).  There is a [separate issue tracker](https://github.com/mietek/halcyon-website/issues/) for problems with the documentation.

Commercial support for Halcyon is offered by [Least Fixed](http://leastfixed.com/), a functional software consultancy.

Need help?  Say [hello](http://leastfixed.com/).


Ac­knowl­edg­ments
---------------

Thanks to [CircuitHub](https://circuithub.com/), [Tweag I/O](http://www.tweag.io/), and [Purely Agile](http://purelyagile.com/) for advice and assistance.


License
-------

Made by [Miëtek Bak](http://mietek.io/).  Published under the [MIT X11 license](http://halcyon.sh/license/).
