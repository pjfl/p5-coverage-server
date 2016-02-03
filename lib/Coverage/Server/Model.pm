package Coverage::Server::Model;

use namespace::autoclean;

use Class::Usul::Constants qw( NUL TRUE );
use Class::Usul::Functions qw( throw );
use Class::Usul::Types     qw( Plinth );
use HTTP::Status           qw( HTTP_BAD_REQUEST HTTP_NOT_FOUND HTTP_OK );
use Scalar::Util           qw( blessed );
use Moo;

with q(Web::Components::Role);

# Public attributes
has 'application' => is => 'ro', isa => Plinth,
   required       => TRUE,  weak_ref => TRUE;

# Public methods
sub exception_handler {
   my ($self, $req, $e) = @_;

   my $name     =  $req->loc( 'Exception Handler' );
   my $errors   =  $e->args->[ 0 ] && blessed $e->args->[ 0 ]
                ?  [ map { "${_}" } @{ $e->args } ] : [];
   my $page     =  {
      errors    => $errors,
      exception => "${e}",
      mtime     => time,
      name      => $name,
      rv        => $e->rv,
      template  => [ 'report', 'exception' ],
      title     => ucfirst $name,
      type      => 'generated' };
   my $stash    =  $self->get_content( $req, $page );

   $stash->{code} = $e->rv >= HTTP_OK ? $e->rv : HTTP_BAD_REQUEST;

   return $stash;
}

sub execute {
   my ($self, $method, @args) = @_;

   $self->can( $method )
      or throw 'Class [_1] has no method [_2]', [ blessed $self, $method ];

   return $self->$method( @args );
}

sub get_content {
   my ($self, $req, $page) = @_; my $stash = $self->initialise_stash( $req );

   $stash->{page} = $self->load_page ( $req, $page  );
   $stash->{nav } = $self->navigation( $req, $stash );

   return $stash;
}

sub initialise_stash {
   return { code => HTTP_OK, view => $_[ 0 ]->config->default_view, };
}

sub load_page {
   my ($self, $req, $page) = @_; $page //= {}; return $page;
}

sub navigation {
   my ($self, $req, $stash) = @_;

   return [ { depth => 0, tip => $req->loc( 'Index Page' ),
              title => 'Home', type => 'file', url => NUL } ];
}

sub not_found {
   my ($self, $req) = @_;

   my $name     =  $req->loc( 'Not Found' );
   my $wanted   =  $req->uri_params->( 0, { optional => TRUE } );
   my $page     =  {
      exception => $req->loc( 'Page "[_1]" not found', $wanted ),
      mtime     => time,
      name      => $name,
      rv        => HTTP_NOT_FOUND,
      template  => [ 'report', 'exception' ],
      title     => ucfirst $name,
      type      => 'generated' };
   my $stash    =  $self->get_content( $req, $page );

   $stash->{code} = HTTP_NOT_FOUND;

   return $stash;
}

1;

__END__

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
