package Coverage::Server::Functions;

use 5.010001;
use strictures;
use parent  'Exporter::Tiny';

use Class::Usul::Constants qw( EXCEPTION_CLASS LANG NUL TRUE );
use Class::Usul::Functions qw( first_char is_arrayref is_hashref
                               my_prefix split_on_dash throw );
use English                qw( -no_match_vars );
use Module::Pluggable::Object;
use Scalar::Util           qw( blessed );
use Unexpected::Functions  qw( Unspecified );
use URI::Escape            qw( );
use URI::http;
use URI::https;

our @EXPORT_OK = qw( build_navigation_list build_tree clone env_var
                     extract_lang iterator load_components make_id_from
                     make_name_from mtime new_uri set_element_focus );

my $reserved   = q(;/?:@&=+$,[]);
my $mark       = q(-_.!~*'());                                    #'; emacs
my $unreserved = "A-Za-z0-9\Q${mark}\E";
my $uric       = quotemeta( $reserved )."${unreserved}%";

# Private functions
my $_get_tip_text = sub {
   my ($root, $node) = @_; my $text = $node->{path}->abs2rel( $root );

   $text =~ s{ \A [a-z]+ / }{}mx;
   $text =~ s{ [/] }{ / }gmx;
   $text =~ s{ [_] }{ }gmx;

   return $text;
};

my $_sorted_keys = sub {
   my $node = shift;

   return [ sort { $node->{ $b }->{_order} <=> $node->{ $a }->{_order} }
            grep { first_char $_ ne '_' } keys %{ $node } ];
};

my $_uric_escape = sub {
    my $str = shift;

    $str =~ s{([^$uric\#])}{ URI::Escape::escape_char($1) }ego;
    utf8::downgrade( $str );
    return \$str;
};

my $_make_tuple = sub {
   my $node = shift; my $is_folder = $node && $node->{type} eq 'folder' ? 1 : 0;

   return [ 0, $is_folder ? $_sorted_keys->( $node->{tree} ) : [], $node, ];
};

# Public functions
sub iterator ($) {
   my $tree = shift; my @folders = ( $_make_tuple->( $tree ) );

   return sub {
      while (my $tuple = $folders[ 0 ]) {
         while (defined (my $k = $tuple->[ 1 ]->[ $tuple->[ 0 ]++ ])) {
            my $node = $tuple->[ 2 ]->{tree}->{ $k };

            $node->{type} eq 'folder'
               and unshift @folders, $_make_tuple->( $node );

            return $node;
         }

         shift @folders;
      }

      return;
   };
}

sub build_navigation_list ($$$$) {
   my ($root, $tree, $prefix, $ids) = @_; my @nav = ();

   my $iter   = iterator $tree;
   my $wanted = join '/', $prefix, grep { defined } @{ $ids };

   while (defined (my $node = $iter->())) {
      $node->{id} eq 'latest' and next;

      my $link = clone( $node ); delete $link->{tree};

      $link->{class}  = $node->{type} eq 'folder' ? 'folder-link' : 'file-link';
      $link->{tip  }  = $_get_tip_text->( $root, $node );
      $link->{depth} -= 2;
      if (defined $ids->[ 0 ] and $ids->[ 0 ] eq $node->{id}) {
         $link->{class} .= $node->{url} eq $wanted ? ' active' : ' open';
         shift @{ $ids };
      }

      push @nav, $link;
   }

   return \@nav;
}

my $node_order;

sub build_tree {
   my ($dir, $url_base, $depth, $no_reset, $parent) = @_;

   $url_base //= NUL; $depth //= 1; $depth++;

   $no_reset or $node_order = 0; $parent //= NUL;

   my $fcount = 0; my $max_mtime = 0; my $tree = {};

   for my $path ($dir->all) {
      my ($id, $pref) =  @{ make_id_from( $path->filename ) };
      my  $name       =  make_name_from( $id );
      my  $url        =  $url_base ? "${url_base}/${id}" : $id;
      my  $mtime      =  $path->stat->{mtime};
      my  $node       =  $tree->{ $id } = {
          date        => $mtime,
          depth       => $depth,
          id          => $id,
          name        => $name,
          parent      => $parent,
          path        => $path->utf8,
          prefix      => $pref,
          title       => ucfirst $name,
          type        => 'file',
          url         => $url,
          _order      => $node_order++, };

      $path->is_file and ++$fcount and $mtime > $max_mtime
                                   and $max_mtime = $mtime;
      $path->is_dir or next;
      $node->{type}  = 'folder';
      $node->{tree}  = build_tree( $path, $url, $depth, $node_order, $name );
      $fcount += $node->{fcount} = $node->{tree}->{_fcount};
      mtime( $node ) > $max_mtime and $max_mtime = mtime( $node );
   }

   $tree->{_fcount} = $fcount; $tree->{_mtime} = $max_mtime;

   return $tree;
}

sub clone (;$) {
   my $v = shift;

   is_arrayref $v and return [ @{ $v // [] } ];
   is_hashref  $v and return { %{ $v // {} } };
   return $v;
}

sub env_var ($;$) {
   my $k = (uc split_on_dash my_prefix $PROGRAM_NAME).'_'.$_[ 0 ];

   return defined $_[ 1 ] ? $ENV{ $k } = $_[ 1 ] : $ENV{ $k };
}

sub extract_lang ($) {
   my $v = shift; return $v ? (split m{ _ }mx, $v)[ 0 ] : LANG;
}

sub load_components ($$;$) {
   my ($builder, $search_path, $opts) = @_; $opts //= {};

   blessed $builder or throw 'Builder [_1] not an object', [ $builder ];
   $search_path     or throw Unspecified, [ 'search path' ];
   $opts->{builder} //= $builder;

   my $config   = $builder->config; my $appclass = $config->appclass;

   if (first_char $search_path eq '+') { $search_path = substr $search_path, 1 }
   else { $search_path = "${appclass}::${search_path}" }

   my $depth    = () = split m{ :: }mx, $search_path, -1; $depth += 1;
   my $finder   = Module::Pluggable::Object->new
      ( max_depth   => $depth,           min_depth => $depth,
        search_path => [ $search_path ], require   => TRUE, );
   my $compos   = $opts->{components} = {}; # Dependency injection

   for my $class ($finder->plugins) {
     (my $klass = $class) =~ s{ \A $appclass :: }{}mx;
      my $attr  = { %{ $config->components->{ $klass } // {} }, %{ $opts } };
      my $comp  = $class->new( $attr ); $compos->{ $comp->moniker } = $comp;
   }

   return $compos;
}

sub make_id_from ($) {
   my $v = shift; my ($p) = $v =~ m{ \A ((?: \d+ [_\-] )+) }mx;

   $v =~ s{ \A (\d+ [_\-])+ }{}mx; $v =~ s{ [_] }{-}gmx;

   defined $p and $p =~ s{ [_\-]+ \z }{}mx;

   return [ $v, $p // NUL ];
}

sub make_name_from ($) {
   my $v = shift; $v =~ s{ [_\-] }{ }gmx; return $v;
}

sub mtime ($) {
   return $_[ 0 ]->{tree}->{_mtime};
}

sub new_uri ($$) {
   return bless $_uric_escape->( $_[ 0 ] ), 'URI::'.$_[ 1 ];
}

sub set_element_focus ($$) {
   my ($form, $name) = @_;

   return [ "var form = document.forms[ '${form}' ];",
            "var f = function() { behaviour.rebuild(); form.${name}.focus() };",
            'f.delay( 100 );', ];
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Coverage::Server::Functions - One-line description of the modules purpose

=head1 Synopsis

   use Coverage::Server::Functions;
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
