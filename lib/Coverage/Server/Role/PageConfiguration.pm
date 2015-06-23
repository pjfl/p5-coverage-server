package Coverage::Server::Role::PageConfiguration;

use namespace::autoclean;

use Coverage::Server::Functions qw( extract_lang );
use Class::Usul::Constants      qw( FALSE NUL TRUE );
use Class::Usul::Types          qw( Object );
use Moo::Role;

requires qw( config load_page );

# Construction
around 'load_page' => sub {
   my ($orig, $self, $req, @args) = @_;

   my $page = $orig->( $self, $req, @args ); my $conf = $self->config;

   for (qw( appclass author description keywords )) {
      $page->{ $_ } //= $conf->$_();
   }

   $page->{template           } = [ @{ $conf->template } ];
   $page->{application_version} = $Coverage::Server::VERSION;
   $page->{hint               } = $req->loc( 'Hint' );
   $page->{language           } = $req->language;
   $page->{locale             } = $req->locale;
   $page->{status_message     } = $req->session->clear_status_message( $req );

   return $page;
};

1;

__END__

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
