package Coverage::Server::Role::PageConfiguration;

use namespace::autoclean;

use Try::Tiny;
use Moo::Role;

requires qw( config initialise_stash load_page log );

# Construction
around 'initialise_stash' => sub {
   my ($orig, $self, $req, @args) = @_;

   my $stash  = $orig->( $self, $req, @args ); my $conf = $self->config;

   my $params = $req->query_params; my $sess = $req->session;

   for my $k (@{ $conf->stash_attr->{session} }) {
      try {
         my $v = $params->( $k, { optional => 1 } );

         $stash->{prefs}->{ $k } = defined $v ? $sess->$k( $v ) : $sess->$k();
      }
      catch { $self->log->warn( $_ ) };
   }

   $stash->{skin} = delete $stash->{prefs}->{skin};

   my $links = $stash->{links} //= {};

   for my $k (@{ $conf->stash_attr->{links} }) {
      $links->{ $k } = $req->uri_for( $conf->$k() );
   }

   $links->{cdnjs   } = $conf->cdnjs;
   $links->{base_uri} = $req->base;
   $links->{req_uri } = $req->uri;
   return $stash;
};

around 'load_page' => sub {
   my ($orig, $self, $req, @args) = @_;

   my $page = $orig->( $self, $req, @args ); my $conf = $self->config;

   for my $k (@{ $conf->stash_attr->{request} }) { $page->{ $k }   = $req->$k  }

   for my $k (@{ $conf->stash_attr->{config } }) { $page->{ $k } //= $conf->$k }

   $page->{application_version} = $conf->appclass->VERSION;
   $page->{status_message     } = $req->session->collect_status_message( $req );

   $page->{hint  } //= $req->loc( 'Hint' );
   $page->{locale} //= $req->locale;

   return $page;
};

1;

__END__

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
