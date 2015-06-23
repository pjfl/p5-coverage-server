# Name

Coverage::Server - Generate badges from test coverage summaries

# Synopsis

    plackup --access-log var/logs/access_5000.log bin/coverage-server

# Description

Receives test coverage summaries from [Devel::Cover::Report::OwnServer](https://metacpan.org/pod/Devel::Cover::Report::OwnServer)
and generates a badge for each report received

# Installation

The `Coverage-Server` repository on Github contains meta data that lists the
CPAN modules used by the application. Modern Perl CPAN distribution installers
(like [App::cpanminus](https://metacpan.org/pod/App::cpanminus)) use this information to install the required
dependencies. Requirements:

- `Perl`

    Version `5.12.0` or newer

- `Git`

    To install `Coverage-Server` from Github

To find out if Perl is installed and which version; at a shell prompt type

    perl -v

To find out if Git is installed, type

    git --version

If you don't already have it, bootstrap [App::cpanminus](https://metacpan.org/pod/App::cpanminus) with:

    curl -L http://cpanmin.us | perl - --sudo App::cpanminus

Then install [local::lib](https://metacpan.org/pod/local::lib) with:

    cpanm --notest --local-lib=~/Coverage-Server local::lib && \
      eval $(perl -I ~/Coverage-Server/lib/perl5/ -Mlocal::lib=~/Coverage-Server)

The second statement sets environment variables to include the local Perl
library. You can append the output of the perl command to your shell startup if
you want to make it permanent. Without the correct environment settings Perl
will not be able to find the installed dependencies and the following will
fail, badly.

Install `Coverage-Server` with:

    cpanm --notest git://github.com/pjfl/p5-coverage-server.git

Although this is a _simple_ application it is composed of many CPAN
distributions and, depending on how many of them are already available,
installation may take a while to complete. The flip side is that there are no
external dependencies like `Node.js` or `Grunt` to install. Anyway you are
advised to seek out sustenance whilst you wait for the installation tests to
complete.  At the risk of installing broken modules (they are only going into a
local library) you can skip the tests by running `cpanm` with the `--notest`
option

If that fails run it again with the `--force` option

    cpanm --force git:...

By default the development server will be found at
`http://localhost:5000/coverage` and can be started in the foreground with:

    cd Coverage-Server
    plackup --access-log var/logs/access_5000.log bin/coverage-server

To start the production server in the background listening on the default port
8085 use:

    coverage-daemon start

The `doh-daemon` program provides normal SysV init script semantics.
Additionally the daemon program will write an init script to standard output in
response to the command:

    coverage-daemon get_init_file

# Configuration and Environment

The configuration file defaults to `lib/Coverage/Server/coverage-server.json`

# Subroutines/Methods

None

# Diagnostics

Setting `COVERAGE_DEBUG` to true in the environment and exporting it causes
the application to log at the debug level

# Dependencies

- [Class::Usul](https://metacpan.org/pod/Class::Usul)
- [Moo](https://metacpan.org/pod/Moo)
- [Plack](https://metacpan.org/pod/Plack)
- [SVG](https://metacpan.org/pod/SVG)
- [Web::Simple](https://metacpan.org/pod/Web::Simple)

# Incompatibilities

There are no known incompatibilities in this module

# Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Coverage-Server.
Patches are welcome

# Acknowledgements

Larry Wall - For the Perl programming language

# Author

Peter Flanigan, `<pjfl@cpan.org>`

# License and Copyright

Copyright (c) 2015 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic)

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
