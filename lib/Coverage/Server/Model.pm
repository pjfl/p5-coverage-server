package Coverage::Server::Model;

use namespace::autoclean;

use Class::Usul::Constants qw( NUL );
use Class::Usul::Functions qw( is_member throw );
use Class::Usul::Time      qw( str2time time2str );
use HTTP::Status           qw( HTTP_BAD_REQUEST HTTP_NOT_FOUND HTTP_OK );
use Scalar::Util           qw( blessed weaken );
use Moo;

with 'Coverage::Server::Role::Component';

# Public methods
sub exception_handler {
   my ($self, $req, $e) = @_;

   my $stash  = $self->initialise_stash( $req );
   my $title  = $req->loc( 'Exception Handler' );
   my $errors = $e->args->[ 0 ] && blessed $e->args->[ 0 ]
              ? [ map { "${_}" } @{ $e->args } ] : [];

   $stash->{code} =  $e->rv >= HTTP_OK ? $e->rv : HTTP_BAD_REQUEST;
   $stash->{page} =  $self->load_page( $req, {
      errors      => $errors,
      exception   => "${e}",
      mtime       => time,
      name        => $title,
      rv          => $e->rv,
      title       => $title,
      type        => 'generated' } );
   $stash->{page}->{template}->[ 1 ] = 'exception';
   $stash->{nav } =  $self->navigation( $req, $stash );

   return $stash;
}

sub execute {
   my ($self, $method, @args) = @_;

   $self->can( $method )
      or throw 'Class [_1] has no method [_2]', [ blessed $self, $method ];

   return $self->$method( @args );
}

sub get_content {
   my ($self, $req) = @_; my $stash = $self->initialise_stash( $req );

   $stash->{page} = $self->load_page ( $req );
   $stash->{nav } = $self->navigation( $req, $stash );

   return $stash;
}

sub initialise_stash {
   my ($self, $req) = @_; weaken( $req );

   return { code         => HTTP_OK,
            functions    => {
               is_member => \&is_member,
               loc       => sub { $req->loc( @_ ) },
               str2time  => \&str2time,
               time2str  => \&time2str,
               ucfirst   => sub { ucfirst $_[ 0 ] },
               uri_for   => sub { $req->uri_for( @_ ), }, },
            req          => $req,
            view         => $self->config->default_view, };
}

sub load_page {
   my ($self, $req, $args) = @_; my $page = $args // {}; return $page;
}

sub navigation {
   my ($self, $req, $stash) = @_;

   return [ { depth => 0, tip => $req->loc( 'Index Page' ),
              title => 'Home', type => 'file', url => NUL } ];
}

sub not_found {
   my ($self, $req) = @_;

   my $stash = $self->initialise_stash( $req );
   my $title = $req->loc( 'Not Found' );

   $stash->{code} =  HTTP_NOT_FOUND;
   $stash->{page} =  $self->load_page( $req, {
      exception   => $req->loc( 'Page "[_1]" not found', $req->args->[ 0 ] ),
      mtime       => time,
      name        => $title,
      rv          => HTTP_NOT_FOUND,
      title       => $title,
      type        => 'generated' } );
   $stash->{page}->{template}->[ 1 ] = 'exception';
   $stash->{nav } =  $self->navigation( $req, $stash );

   return $stash;
}

1;

__END__

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
