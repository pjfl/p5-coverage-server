package Coverage::Server;

use 5.010001;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1 $ =~ /\d+/gmx );

use Class::Usul;
use Class::Usul::Constants  qw( NUL TRUE );
use Class::Usul::Types      qw( HashRef Plinth );
use Coverage::Server::Util  qw( enhance env_var );
use Plack::Builder;
use Web::Simple;

# Private attributes
has '_config_attr' => is => 'ro', isa => HashRef, builder => sub { {} },
   init_arg => 'config';

has '_usul' => is => 'lazy', isa => Plinth,
   builder  => sub { Class::Usul->new( enhance $_[ 0 ]->_config_attr ) },
   handles  => [ 'config', 'debug', 'dumper', 'l10n', 'lock', 'log' ];

with 'Web::Components::Loader';

# Construction
around 'to_psgi_app' => sub {
   my ($orig, $self, @args) = @_; my $app = $orig->( $self, @args );

   my $conf = $self->config; my $static = $conf->serve_as_static;

   return builder {
      mount $conf->mount_point => builder {
         enable 'ContentLength';
         enable 'FixMissingBodyInRedirect';
         enable "ConditionalGET";
         enable 'Deflater',
            content_type => $conf->deflate_types, vary_user_agent => TRUE;
         enable 'Static',
            path => qr{ \A / (?: $static ) }mx, root => $conf->root;
         enable 'Session::Cookie',
            expires     => 7_776_000,
            httponly    => TRUE,
            path        => $conf->mount_point,
            secret      => $conf->secret.NUL,
            session_key => $conf->prefix.'_session';
         enable "LogDispatch", logger => $self->log;
         enable_if { $self->debug } 'Debug';
         $app;
      };
   };
};

sub BUILD {
   my $self   = shift;
   my $server = ucfirst( $ENV{PLACK_ENV} // NUL );
   my $port   = env_var $self->config->appclass, 'PORT';
   my $info   = 'v'.$VERSION; $port and $info .= " on port ${port}";

   $self->log->info( "${server} Server started ${info}" );

   return;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Coverage::Server - Generate badges from test coverage summaries

=head1 Synopsis

   plackup --access-log var/logs/access_5000.log bin/coverage-server

=head1 Description

Receives test coverage summaries from L<Devel::Cover::Report::OwnServer>
and generates a badge for each report received

=head1 Installation

The C<Coverage-Server> repository on Github contains meta data that lists the
CPAN modules used by the application. Modern Perl CPAN distribution installers
(like L<App::cpanminus>) use this information to install the required
dependencies. Requirements:

=over 3

=item C<Perl>

Version C<5.12.0> or newer

=item C<Git>

To install C<Coverage-Server> from Github

=back

To find out if Perl is installed and which version; at a shell prompt type

   perl -v

To find out if Git is installed, type

   git --version

If you don't already have it, bootstrap L<App::cpanminus> with:

   curl -L http://cpanmin.us | perl - --sudo App::cpanminus

Then install L<local::lib> with:

   cpanm --notest --local-lib=~/Coverage-Server local::lib && \
     eval $(perl -I ~/Coverage-Server/lib/perl5/ -Mlocal::lib=~/Coverage-Server)

The second statement sets environment variables to include the local Perl
library. You can append the output of the perl command to your shell startup if
you want to make it permanent. Without the correct environment settings Perl
will not be able to find the installed dependencies and the following will
fail, badly.

Install C<Coverage-Server> with:

   cpanm --notest git://github.com/pjfl/p5-coverage-server.git

Although this is a I<simple> application it is composed of many CPAN
distributions and, depending on how many of them are already available,
installation may take a while to complete. The flip side is that there are no
external dependencies like C<Node.js> or C<Grunt> to install. Anyway you are
advised to seek out sustenance whilst you wait for the installation tests to
complete.  At the risk of installing broken modules (they are only going into a
local library) you can skip the tests by running C<cpanm> with the C<--notest>
option

If that fails run it again with the C<--force> option

   cpanm --force git:...

By default the development server will be found at
C<http://localhost:5000/coverage> and can be started in the foreground with:

   cd Coverage-Server
   plackup --access-log var/logs/access_5000.log bin/coverage-server

To start the production server in the background listening on the default port
8085 use:

   coverage-daemon start

The C<doh-daemon> program provides normal SysV init script semantics.
Additionally the daemon program will write an init script to standard output in
response to the command:

   coverage-daemon get_init_file

=head1 Configuration and Environment

The configuration file defaults to F<lib/Coverage/Server/coverage-server.json>

=head1 Subroutines/Methods

=head2 C<BUILD>

Log some diagnostic information when the application starts

=head2 C<to_psgi_app>

Load the L</Plack> stack with middleware

=head1 Diagnostics

Setting C<COVERAGE_SERVER_DEBUG> to true in the environment and exporting it
causes the application to log at the debug level

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<Moo>

=item L<Plack>

=item L<SVG>

=item L<Web::Simple>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Coverage-Server.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2015 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
