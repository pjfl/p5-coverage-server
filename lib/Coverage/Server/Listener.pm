package Coverage::Server::Listener;

use namespace::autoclean;

use Class::Usul;
use Class::Usul::Constants      qw( NUL TRUE );
use Class::Usul::Functions      qw( ensure_class_loaded );
use Class::Usul::Types          qw( HashRef Plinth );
use Coverage::Server::Functions qw( enhance env_var );
use Plack::Builder;
use Web::Simple;

# Private attributes
has '_config_attr' => is => 'ro',   isa => HashRef,
   builder         => sub { {} }, init_arg => 'config';

has '_usul'        => is => 'lazy', isa => Plinth,
   builder         => sub { Class::Usul->new( enhance $_[ 0 ]->_config_attr ) },
   handles         => [ 'config', 'debug', 'l10n', 'lock', 'log' ];

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
            session_key => 'coverage_session';
         enable "LogDispatch", logger => $self->log;
         enable_if { $self->debug } 'Debug';
         $app;
      };
   };
};

sub BUILD {
   my $self   = shift;
   my $conf   = $self->config;
   my $server = ucfirst( $ENV{PLACK_ENV} // NUL );
   my $class  = $conf->appclass; ensure_class_loaded $class;
   my $port   = env_var $class, 'PORT';
   my $info   = 'v'.$class->VERSION; $port and $info .= " on port ${port}";

   $self->log->info( "${server} Server started ${info}" );

   return;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Coverage::Server::Listener - One-line description of the modules purpose

=head1 Synopsis

   use Coverage::Server::Listener;
   # Brief but working code examples

=head1 Description

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=back

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Dependencies

=over 3

=item L<Class::Usul>

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
