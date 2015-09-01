package Coverage::Server::Functions;

use 5.010001;
use strictures;
use parent 'Exporter::Tiny';

use Class::Usul::Constants qw( EXCEPTION_CLASS NUL );
use Class::Usul::Functions qw( app_prefix env_prefix find_apphome first_char
                               get_cfgfiles is_arrayref is_hashref throw );
use Unexpected::Functions  qw( Unspecified );

our @EXPORT_OK = qw( build_navigation_list build_tree clone env_var enhance
                     iterator make_id_from make_name_from mtime
                     set_element_focus );

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

my $_make_tuple = sub {
   my $node = shift; my $is_folder = $node && $node->{type} eq 'folder' ? 1 : 0;

   return [ 0, $is_folder ? $_sorted_keys->( $node->{tree} ) : [], $node, ];
};

# Public functions
sub build_navigation_list ($$$$) {
   my ($root, $tree, $prefix, $ids) = @_; my $iter = iterator( $tree );

   my $wanted = join '/', $prefix, grep { defined } @{ $ids }; my @nav = ();

   while (defined (my $node = $iter->())) {
      $node->{id} eq 'latest' and next;

      my $link = clone( $node ); delete $link->{tree};

      $link->{class}  = $node->{type} eq 'folder' ? 'folder-link' : 'file-link';
      $link->{tip  }  = $_get_tip_text->( $root, $node );
      $link->{depth} -= 1;

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
   my ($dir, $url_base, $depth, $no_reset, $parent) = @_; $url_base //= NUL;

   $depth //= 0; $depth++; $no_reset or $node_order = 0; $parent //= NUL;

   my $fcount = 0; my $max_mtime = 0; my $tree = {};

   for my $path ($dir->all) {
      my ($id, $pref) =  @{ make_id_from( $path->utf8->filename ) };
      my  $name       =  make_name_from( $id );
      my  $url        =  $url_base ? "${url_base}/${id}" : $id;
      my  $mtime      =  $path->stat->{mtime};
      my  $node       =  $tree->{ $id } = {
          date        => $mtime,
          depth       => $depth,
          id          => $id,
          name        => $name,
          parent      => $parent,
          path        => $path,
          prefix      => $pref,
          title       => ucfirst $name,
          type        => 'file',
          url         => $url,
          _order      => $node_order++, };

      $path->is_file and $fcount++ and $mtime > $max_mtime
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

sub enhance ($) {
   my $conf = shift;
   my $attr = { config => { %{ $conf } }, }; $conf = $attr->{config};

   $conf->{appclass    } or  throw Unspecified, [ 'application class' ];
   $attr->{config_class} //= $conf->{appclass}.'::Config';
   $conf->{name        } //= app_prefix   $conf->{appclass};
   $conf->{home        } //= find_apphome $conf->{appclass}, $conf->{home};
   $conf->{cfgfiles    } //= get_cfgfiles $conf->{appclass}, $conf->{home};

   $conf->{l10n_attributes}->{domains} = [ $conf->{name} ];

   return $attr;
}

sub env_var ($$;$) {
   my ($class, $var, $v) = @_; my $k = (env_prefix $class)."_${var}";

   return defined $v ? $ENV{ $k } = $v : $ENV{ $k };
}

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
