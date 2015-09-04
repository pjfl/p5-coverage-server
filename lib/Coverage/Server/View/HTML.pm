package Coverage::Server::View::HTML;

use namespace::autoclean;

use Class::Usul::Constants qw( TRUE );
use Class::Usul::Functions qw( is_hashref );
use Class::Usul::Types     qw( Plinth );
use Coverage::Server::Util qw( stash_functions );
use Encode                 qw( encode );
use HTML::FormWidgets;
use Moo;

with 'Web::Components::Role';
with 'Web::Components::Role::TT';

# Public attributes
has 'application' => is => 'ro', isa => Plinth,
   required       => TRUE,  weak_ref => TRUE;

has '+moniker'    => default => 'html';

# Private functions
my $_header = sub {
   return [ 'Content-Type' => 'text/html', @{ $_[ 0 ] // [] } ];
};

# Public methods
sub serialize {
   my ($self, $req, $stash) = @_; stash_functions $self, $req, $stash;

   my $html = encode( $self->encoding, $self->render_template( $stash ) );

   return [ $stash->{code}, $_header->( $stash->{http_headers} ), [ $html ] ];
}

around 'serialize' => sub {
   my ($orig, $self, $req, $stash) = @_; my $page = $stash->{page} //= {};

   exists $page->{content} and is_hashref $page->{content}
      and $page->{content}->{widget}
      and $page->{content} = HTML::FormWidgets->new( $page->{content} )->render;

   return $orig->( $self, $req, $stash );
};

1;

__END__

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
