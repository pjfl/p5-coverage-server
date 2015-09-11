package Coverage::Server::Model::Report;

use namespace::autoclean;

use Class::Usul::Constants qw( FALSE NUL TRUE );
use Class::Usul::Functions qw( symlink throw );
use Class::Usul::Response::Table;
use Coverage::Server::Util qw( build_navigation_list
                               build_tree clone iterator );
use HTTP::Status           qw( HTTP_OK HTTP_UNAUTHORIZED );
use JSON::MaybeXS          qw( decode_json encode_json );
use SVG;
use Moo;

extends 'Coverage::Server::Model';
with    'Coverage::Server::Role::PageConfiguration';

# Public attributes
has '+moniker' => default => 'report';

# Private package caches
my $_badge_cache        = {};
my $_coverage_cache     = {};
my $_distribution_cache = {};
my $_navigation_cache   = {};
my $_page_cache         = {};
my $_report_cache       = {};

# Private subroutines
my $_colour_band = sub {
   my $coverage = shift;

   $coverage == 100 and return '#4c1';
   $coverage >   90 and return '#ff9';
   $coverage >   75 and return '#fc9';

   return '#f99';
};

my $_create_distribution_table = sub {
   my ($self, $req) = @_; my $rows = [];

   for my $dist (map { $_->basename } $self->config->datadir->all_dirs) {
      push @{ $rows }, {
         id          => $dist,
         coverage    => {
            fhelp    => 'Coverage Badge',
            href     => $req->uri_for( "report/${dist}/latest" ),
            imgclass => 'badge',
            text     => $req->uri_for( "badge/${dist}/latest" ),
            type     => 'anchor',
            widget   => TRUE, } };
   }

   return Class::Usul::Response::Table->new( {
      count  => scalar @{ $rows },
      fields => [ 'id', 'coverage' ],
      labels => { 'id' => 'Distribution', },
      values => $rows,
   } );
};

my $_create_summary_table = sub {
   my $summary = shift;
   my $fields  = [ qw( id statement branch condition subroutine pod total ) ];
   my $rows    = [];

   for my $k ((sort grep { not m{ Total }mx } keys %{ $summary }), 'Total') {
      my $row = { id => $k };

      for my $field (grep { $_ ne 'id' } @{ $fields } ) {
         my $v = $summary->{ $k }->{ $field }->{percentage};

         defined $v and $v = int (0.5 + 10 * $v) / 10;
         $row->{ $field } = $v // 'n/a';
      }

      push @{ $rows }, $row;
   }

   return Class::Usul::Response::Table->new( {
      count  => scalar @{ $rows },
      fields => $fields,
      labels => { 'id' => 'Distribution', },
      values => $rows,
   } );
};

my $_get_coverage_data = sub { # TODO: This method needs caching
   my ($self, $dist, $version) = @_; $version //= 'latest';

   my $file = $self->config->datadir->catfile( $dist, $version );

   $file->exists or return [ 'none', '#bbb', '#f00' ];

   my $report   = decode_json $file->chomp->all;
   my $summary  = $report->{summary};
   my $coverage = $summary->{Total}->{statement}->{percentage};

   $coverage = int( 0.5 + 10 * $coverage ) / 10;

   my $fill = $_colour_band->( $coverage );

   return [ "${coverage}%", $fill, $coverage == 100 ? '#fff' : '#000' ];
};

my $_invalidate_caches = sub {
   my $self  = shift;

   my $file  = $self->config->data_mtime; my $data_mtime = $file->stat->{mtime};

   my $mtime = time; until ($mtime > $data_mtime) { sleep 1; $mtime = time }

   $file->touch( $mtime ); $self->log->debug( 'Caches invalidated' );

   return;
};

my $_json_header = sub {
   return [ 'Content-Type' => 'application/json', @{ $_[ 0 ] // [] } ];
};

my $_report_tree = sub {
   my $self = shift; my $conf = $self->config;

   my $data_mtime = $conf->data_mtime->stat->{mtime};

   if (not defined $_report_cache->{mtime}
        or $data_mtime > $_report_cache->{mtime}) {
      my $no_index = join '|', @{ $conf->no_index };
      my $filter   = sub { not m{ (?: $no_index ) }mx };
      my $root     = $conf->datadir->clone->filter( $filter );

      $_report_cache = { mtime => $data_mtime,
                         tree  => build_tree( $root, 'report' ),
                         type  => 'folder', };
   }

   return $_report_cache;
};

my $_svg_group = sub {
   my ($svg, $colour) = @_;

   return $svg->g
      ( 'fill'        => $colour,
        'font-family' => 'DejaVu Sans,Verdana,Geneva,sans-serif',
        'font-size'   => 11, 'text-anchor' => 'middle' );
};

my $_svg_text = sub {
   my ($group, $x, $y, $text) = @_;

   $group->text( 'fill' => '#010101', 'fill-opacity' => '.3',
                 'x' => $x, 'y' => $y     )->cdata( $text );
   $group->text( 'x' => $x, 'y' => $y - 1 )->cdata( $text );

   return;
};

my $_create_coverage_badge = sub {
   my ($coverage, $fill, $colour) = @_;

   $_badge_cache->{ $coverage } and return $_badge_cache->{ $coverage };

   my $svg = SVG->new( 'height' => 20, 'width' => 100, '-nocredits' => TRUE, );
   my $svg_version = $svg->VERSION;

   $svg->comment( "\n\tGenerated using the Perl SVG v${svg_version}" );

   my $grad = $svg->gradient
      ( '-type' => 'linear', 'id' => 'a', 'x2' => 0, 'y2' => '100%' );

   $grad->stop( 'offset' => 0, 'stop-color' => '#bbb', 'stop-opacity' => '.1' );
   $grad->stop( 'offset' => 1, 'stop-opacity' => '.1');

   $svg->rect( 'fill' => '#555', 'height' => 20, 'rx' => 3, 'width' => 100 );
   $svg->rect
      ( 'fill' => $fill, 'height' => 20, 'rx' => 3, 'x' => 62, 'width' => 38 );
   $svg->path( 'd' => 'M60 0h4v20h-4z', 'fill' => $fill );
   $svg->rect( 'fill' => 'url(#a)', 'height' => 20, 'rx' => 3, 'width' => 100 );

   $_svg_text->( $_svg_group->( $svg, '#fff'  ), 27.5, 15, 'coverage' );
   $_svg_text->( $_svg_group->( $svg, $colour ), 80,   15, $coverage  );

   return $_badge_cache->{ $coverage } = $svg->xmlify( '-namespace' => 'svg' );
};

my $_find_node = sub {
   my ($self, $args) = @_; my $node = $self->$_report_tree;

   my $ids = [ @{ $args } ]; $ids->[ 0 ] or $ids->[ 0 ] = 'index';

   for my $node_id (grep { defined } @{ $ids }) {
      $node->{type} eq 'folder' and $node = $node->{tree};
      exists  $node->{ $node_id } or return FALSE;
      $node = $node->{ $node_id };
   }

   return $node;
};

my $_initialise_page = sub {
   my ($self, $req, $node) = @_; $node or return {};

   my $page   = clone $node;
   my $path   = delete $page->{path}; $page->{type} eq 'file' or return $page;
   my $cached = $_page_cache->{ $page->{url} };
   my $tree   = $self->$_report_tree;

   $cached and $cached->{mtime} >= $tree->{mtime} and return $cached;

   my $report = decode_json $path->all;
   my $table  = $_create_summary_table->( $report->{summary} );

   $page->{content} = { data => $table, type => 'table', widget => TRUE };
   $page->{parent } = $report->{info}->{dist_name};
   $page->{mtime  } = $tree->{mtime};

   return $_page_cache->{ $page->{url} } = $page;
};

#Construction
around 'load_page' => sub {
   my ($orig, $self, $req, @args) = @_;

   $args[ 0 ] and return $orig->( $self, $req, @args );

   my $dist = $req->uri_params->( 0, { optional => TRUE } );
   my $ver  = $req->uri_params->( 1, { optional => TRUE } );

   $dist and not $ver and $ver = 'latest';

   my $node = $self->$_find_node( [ $dist, $ver ] );

   return $orig->( $self, $req, $self->$_initialise_page( $req, $node ) );
};

sub BUILD {
   my $self = shift;

   $self->$_report_tree; # Take the hit at startup not on first request

   return;
}

# Public methods
sub add_report {
   my ($self, $req) = @_; my $content;

   my $conf    = $self->config;
   my $dist    = $req->uri_params->( 0 );
   my $body_p  = $req->body_params;
   my $info    = $body_p->( 'info',    { raw => TRUE } );
   my $summary = $body_p->( 'summary', { raw => TRUE } );
   my ($major, $minor) = split m{ \. }mx, $info->{version};
   my $latest  = $conf->datadir->catfile( $dist, 'latest' );
   my $s_file  = $conf->datadir->catfile( $dist, "${major}.${minor}" );
   my $token   = $info->{coverage_token} or throw 'No authentication token';
   my $report  = { info => $info, summary => $summary };

   $token ne $conf->coverage_token
      and $content = encode_json { message => 'Coverage authentication failed' }
      and return [ HTTP_UNAUTHORIZED, $_json_header->(), [ $content ] ];

   $s_file->assert_filepath->print( encode_json $report );
   $latest->exists and $latest->unlink; symlink $s_file, $latest;
   $content = encode_json { message => 'Posted coverage summary' };
   $self->$_invalidate_caches;

   return [ HTTP_OK, $_json_header->(), [ $content ] ];
}

sub get_badge {
   my ($self, $req) = @_;

   my $dist    = $req->uri_params->( 0 );
   my $version = $req->uri_params->( 1, { optional => TRUE } );
   my $data    = $self->$_get_coverage_data( $dist, $version );
   my $content = $_create_coverage_badge->( @{ $data } );

   return [ HTTP_OK, [ 'Content-Type' => 'image/svg+xml' ], [ $content ] ];
}

sub get_help {
   my ($self, $req) = @_; return $self->get_content( $req );
}

sub get_latest {
   my ($self, $req) = @_; return $self->get_content( $req );
}

sub get_reports {
   my ($self, $req) = @_;

   my $tree = $self->$_report_tree; my $cache = $_distribution_cache->{index};

   (not $cache or $tree->{mtime} > $cache->{mtime})
      and $cache = $_distribution_cache->{index}
         = { table => $self->$_create_distribution_table( $req ),
             mtime => $tree->{mtime}, };

   my $page = { content   => {
                   data   => $cache->{table},
                   type   => 'table',
                   widget => TRUE, },
                title     => $req->loc( 'Coverage by Distribution' ), };

   return $self->get_content( $req, $page );
}

sub navigation {
   my ($self, $req, $stash) = @_;

   my $root   = $self->config->datadir;
   my $tree   = $self->$_report_tree;
   my $dist   = $req->uri_params->( 0, { optional => TRUE } );
   my $ver    = $req->uri_params->( 1, { optional => TRUE } );
   my $wanted = $dist ? $ver ? "${dist}/${ver}" : $dist : NUL;
   my $nav    = $_navigation_cache->{ $wanted };

   (not $nav or $tree->{mtime} > $nav->{mtime})
      and $nav = $_navigation_cache->{ $wanted }
         = { list  => build_navigation_list
                ( $root, $tree, 'report', [ $dist, $ver ] ),
             mtime => $tree->{mtime}, };

   return $nav->{list};
}

1;

__END__

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
