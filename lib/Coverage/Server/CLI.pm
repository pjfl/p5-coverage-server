package Coverage::Server::CLI;

use namespace::autoclean;

use Class::Usul::Constants   qw( CONFIG_EXTN FALSE NUL OK TRUE );
use Class::Usul::Crypt::Util qw( encrypt_for_config );
use Class::Usul::Functions   qw( arg_list class2appdir ensure_class_loaded
                                 throw );
use Moo;

extends q(Class::Usul::Programs);

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $args = arg_list @args;

   my $conf = $args->{config} //= {}; $conf->{appclass} //= 'Coverage::Server';

   $args->{config_class} //= $conf->{appclass}.'::Config';
   $conf->{name        } //= class2appdir $conf->{appclass};
   $conf->{l10n_domains} //= [ $conf->{name} ];

   return $orig->( $self, $args );
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
