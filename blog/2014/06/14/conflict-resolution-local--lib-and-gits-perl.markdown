---
author: preaction
last_modified: 2014-06-14 21:25:31
tags: perl, git
links:
    crosspost:
        title: blogs.perl.org
        href: http://blogs.perl.org/users/preaction/2014/06/conflict-resolution-locallib-and-gits-perl.html
title: Conflict Resolution: local::lib and git's Perl
---
I ran into a frustrating problem the other day:

    $ git add -i
    /usr/bin/perl: symbol lookup error: ~/perl5/lib/perl5/x86_64-linux-thread-multi/auto/List/Util/Util.so:
    undefined symbol: Perl_xs_apiversion_bootcheck
    fatal: 'add--interactive' appears to be a git command, but we were not
    able to execute it. Maybe git-add--interactive is broken?

---

I've seen this error message from Perl a lot. It basically means that I'm
trying to load an XS module compiled for a different version of Perl. Since
`git` is directly trying to run `/usr/bin/perl` (5.10.1) as opposed to the
`perlbrew` Perl I have installed (5.16.3), the error comes as no surprise:
`PERL5LIB` is checked before Perl's built-in libraries. So if you have a
`local::lib` (which adds its directories to `PERL5LIB`) and try to use those
modules in a different Perl, things may not work as you expected.

What is more surprising is that Git explicitly uses `/usr/bin/perl` in the
first place. Some Google-fu brought up a [thread on the Git mailing list about
changing to `#!/usr/bin/env
perl`](http://article.gmane.org/gmane.comp.version-control.git/147462), but it
appears this was rejected. According to another post in that thread, [it is
possible to set PERL_PATH when running `make` on
Git](http://article.gmane.org/gmane.comp.version-control.git/147475), but that
did not seem to work for me.

But the Git Perl scripts all seem to have one thing in common: They all add the
paths in the `GITPERLLIB` environment variable to the front of `@INC` as
the first thing they do. `GITPERLLIB` is treated as a `:`-delimited list of
directories, like `PERL5LIB`. So if we fill in `GITPERLLIB` with the right
directories, we can ensure that the right `List::Util` version is found
first.

The right directories are part of Perl's `Config`. This configuration is
available to us in Perl scripts through the `Config` module which provides a
`%Config` hash.  There are three "layers" of Perl library paths, "core",
"vendor", and "site", configured in the following Config keys:

* core    => 'archlib', 'privlib'
* vendor  => 'vendorarch', 'vendorlib'
* site    => 'sitearch', 'sitelib'

The "core" libraries are just that, the core Perl 5 libraries. The "vendor"
libraries are additional libraries that your vendor may have provided in their
Perl distribution. The "site" libraries are the CPAN libraries you've
downloaded and installed via the `cpan` client (unless you're using local::lib,
which overrides the install directories).

Armed with these Config keys, we can make a `GITPERLLIB` that overrides our local::lib
directories. So now, in my `.zshrc`, I have:

    # Fix git perl scripts in case of local::lib
    # If we install modules for a different arch in local::lib, we'll get some problems
    if [[ -x /usr/bin/perl ]]; then
        export GITPERLLIB=`/usr/bin/perl -MConfig -e'print join ":", grep { $_ } map { $Config{$_} } qw( sitearch sitelib vendorarch vendorlib archlib privlib )'`
    fi

Now I can do my proper `git add --interactive` again!
