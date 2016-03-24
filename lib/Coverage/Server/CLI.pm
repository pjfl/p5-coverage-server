package Coverage::Server::CLI;

use namespace::autoclean;

use Class::Usul::Constants   qw( CONFIG_EXTN FALSE NUL OK TRUE );
use Class::Usul::Crypt::Util qw( encrypt_for_config );
use Class::Usul::Functions   qw( arg_list class2appdir ensure_class_loaded
                                 throw );
use Class::Usul::Types       qw( LoadableClass NonEmptySimpleStr Object );
use Moo;
use Class::Usul::Options;

extends q(Class::Usul::Programs);

my $_build_less = sub {
   my $self = shift; my $conf = $self->config;

   return $self->less_class->new
      ( compress      =>   $conf->compress_css,
        include_paths => [ $conf->root->catdir( 'less' )->pathname ],
        tmp_path      =>   $conf->tempdir, );
};

option 'skin'         => is => 'lazy', isa => NonEmptySimpleStr, format => 's',
   documentation      => 'Name of the skin to operate on',
   builder            => sub { $_[ 0 ]->config->skin }, short => 's';

has 'less'            => is => 'lazy', isa => Object, builder => $_build_less;

has 'less_class'      => is => 'lazy', isa => LoadableClass,
   default            => 'CSS::LESS';

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $args = arg_list @args;

   my $conf = $args->{config} //= {}; $conf->{appclass} //= 'Coverage::Server';

   $args->{config_class} //= $conf->{appclass}.'::Config';
   $conf->{name        } //= class2appdir $conf->{appclass};
   $conf->{l10n_domains} //= [ $conf->{name} ];

   return $orig->( $self, $args );
};

my $_write_theme = sub {
   my ($self, $cssd, $file) = @_;

   my $skin = $self->skin;
   my $conf = $self->config;
   my $path = $conf->root->catfile( $conf->less, $skin, "${file}.less" );

   $path->exists or return;

   my $css  = $self->less->compile( $path->all );

   $self->info( 'Writing theme file [_1]', { args => [ "${skin}-${file}" ] } );
   $cssd->catfile( "${skin}-${file}.css" )->println( $css );
   return;
};

sub encrypt : method {
   my $self  = shift;
   my $file  = $self->file;
   my $conf  = $self->config;
   my $path  = $conf->ctlfile;
   my $data  = $path->exists ? $file->data_load( paths => [ $path ] ) : {};
   my $value = $self->get_line( '+Token', NUL, TRUE, 25, FALSE, TRUE );
   my $again = $self->get_line( '+Again', NUL, TRUE, 25, FALSE, TRUE );

   $value ne $again and throw 'Tokens do not match';
   $data->{token} = encrypt_for_config $conf, $value;
   $file->data_dump( path => $path, data => $data );
   return OK;
}

sub make_css : method {
   my $self = shift;
   my $conf = $self->config;
   my $cssd = $conf->root->catdir( $conf->css );

   if (my $file = $self->next_argv) { $self->$_write_theme( $cssd, $file ) }
   else { $self->$_write_theme( $cssd, $_ ) for (@{ $conf->less_files }) }

   return OK;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Coverage::Server::CLI - Application command line interface

=head1 Synopsis

   use Coverage::Server::CLI;

   exit Coverage::Server::CLI->new_with_options( noask => 1 )->run;

=head1 Description

Application command line interface

=head1 Configuration and Environment

Defines no attributes. Inherits from L<Class::Usul::Programs>. Defaults the
configuration class to L<Coverage::Server::Config>

=head1 Subroutines/Methods

=head2 C<encrypt> - Encrypts and stores the authentication token

Prompts for the authentication token, encrypts it and stores it in the
control file, F<var/etc/coverage-server.json>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<Moo>

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
