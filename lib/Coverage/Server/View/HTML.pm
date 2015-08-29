package Coverage::Server::View::HTML;

use namespace::autoclean;

use Class::Usul::Functions qw( is_hashref );
use Encode                 qw( encode );
use HTML::FormWidgets;
use Moo;

with q(Web::Components::Role);
with q(Coverage::Server::Role::Templates);

# Public attributes
has '+moniker' => default => 'html';

# Private functions
my $_header = sub {
   return [ 'Content-Type' => 'text/html', @{ $_[ 0 ] // [] } ];
};

# Private methods
my $_render_page = sub {
   my ($self, $req, $page) = @_;

   (exists $page->{content} and is_hashref $page->{content}
       and $page->{content}->{widget}) or return;

   $page->{content} = HTML::FormWidgets->new( $page->{content} )->render;

   return;
};

# Public methods
sub serialize {
   my ($self, $req, $stash) = @_; my $enc = $self->encoding;

   $self->$_render_page( $req, $stash->{page} );

   my $html = encode( $enc, $self->render_template( $req, $stash ) );

   return [ $stash->{code}, $_header->( $stash->{http_headers} ), [ $html ] ];
}

1;

__END__

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
