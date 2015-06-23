package Coverage::Server::Role::Component;

use namespace::autoclean;

use Class::Usul::Constants qw( TRUE );
use Class::Usul::Types     qw( BaseType HashRef NonEmptySimpleStr
                               NonNumericSimpleStr );
use Moo::Role;

has 'components' => is => 'ro',   isa => HashRef, default => sub { {} },
   weak_ref      => TRUE;

has 'encoding'   => is => 'lazy', isa => NonEmptySimpleStr,
   builder       => sub { $_[ 0 ]->config->encoding };

has 'moniker'    => is => 'ro',   isa => NonNumericSimpleStr, required => TRUE;

has 'usul'       => is => 'ro',   isa => BaseType,
   handles       => [ qw( config debug l10n lock log ) ],
   init_arg      => 'builder', required => TRUE;

1;

__END__

=pod

=encoding utf-8

=head1 Name

Coverage::Server::TraitFor::Component - One-line description of the modules purpose

=head1 Synopsis

   use Coverage::Server::TraitFor::Component;
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
