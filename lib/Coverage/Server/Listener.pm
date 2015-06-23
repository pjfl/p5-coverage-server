package Coverage::Server::Listener;

use namespace::autoclean;

use Coverage::Server::Functions qw( env_var );
use Class::Usul;
use Class::Usul::Constants      qw( EXCEPTION_CLASS FALSE NUL TRUE );
use Class::Usul::Functions      qw( app_prefix ensure_class_loaded
                                    find_apphome get_cfgfiles throw );
use Class::Usul::Types          qw( BaseType );
use Plack::Builder;
use Unexpected::Functions       qw( Unspecified );
use Web::Simple;

# Attribute constructors
my $_build_usul = sub {
   my $self = shift;
   my $attr = { config => $self->config, debug => env_var( 'DEBUG' ) // FALSE };
   my $conf = $attr->{config};

   $conf->{appclass    } or  throw Unspecified, [ 'application class' ];
   $attr->{config_class} //= $conf->{appclass}.'::Config';
   $conf->{name        } //= app_prefix   $conf->{appclass};
   $conf->{home        } //= find_apphome $conf->{appclass}, $conf->{home};
   $conf->{cfgfiles    } //= get_cfgfiles $conf->{appclass}, $conf->{home};

   $conf->{l10n_attributes}->{domains} = [ $conf->{name} ];

   return Class::Usul->new( $attr );
};

# Public attributes
has 'usul' => is => 'lazy', isa => BaseType,
   builder => $_build_usul, handles => [ 'log' ];

with 'Coverage::Server::Role::ComponentLoading';

# Construction
around 'to_psgi_app' => sub {
   my ($orig, $self, @args) = @_; my $app = $orig->( $self, @args );

   my $conf   = $self->usul->config;
   my $point  = $conf->mount_point;
   my $static = $conf->serve_as_static;

   return builder {
      mount "${point}" => builder {
         enable 'ContentLength';
         enable 'FixMissingBodyInRedirect';
         enable "ConditionalGET";
         enable 'Deflater',
            content_type => $conf->deflate_types, vary_user_agent => TRUE;
         enable 'Static',
            path => qr{ \A / (?: $static ) }mx, root => $conf->root;
         enable 'Session::Cookie',
            expires     => 7_776_000, httponly => TRUE,
            path        => $point,    secret   => NUL.$conf->secret,
            session_key => 'coverage_session';
         enable "LogDispatch", logger => $self->usul->log;
         enable_if { $self->usul->debug } 'Debug';
         $app;
      };
   };
};

sub BUILD {
   my $self   = shift;
   my $server = ucfirst( $ENV{PLACK_ENV} // NUL );
   my $port   = env_var( 'PORT' ) ? ' on port '.env_var( 'PORT' ) : NUL;
   my $class  = $self->usul->config->appclass; ensure_class_loaded $class;
   my $ver    = $class->VERSION;

   $self->log->info( "${server} Server started v${ver}${port}" );

   return;
}

# Public methods
sub dispatch_request {
   my $f = sub () { my $self = shift; response_filter { $self->render( @_ ) } };

   return $f, map { $_->dispatch_request } @{ $_[ 0 ]->controllers };
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
