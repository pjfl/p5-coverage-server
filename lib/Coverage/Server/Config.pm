package Coverage::Server::Config;

use namespace::autoclean;

use Class::Usul::Constants qw( NUL TRUE );
use File::DataClass::Types qw( ArrayRef Bool HashRef NonEmptySimpleStr
                               NonZeroPositiveInt Object Path
                               PositiveInt SimpleStr Str Undef );
use Type::Utils            qw( as coerce from subtype via );
use Moo;

extends 'Class::Usul::Config::Programs';

my $SECRET = subtype as Object;

coerce $SECRET, from Str, via { Coverage::Server::_Secret->new( value => $_ ) };

# Private functions
my $_to_array_of_hash = sub {
   my ($href, $key_key, $val_key) = @_;

   return [ map { my $v = $href->{ $_ }; +{ $key_key => $_, $val_key => $v } }
            sort keys %{ $href } ],
};

# Attribute constructors
my $_build_cdnjs = sub {
   my $self  = shift;
   my %cdnjs = map { $_->[ 0 ] => $self->cdn.$_->[ 1 ] } @{ $self->jslibs };

   return \%cdnjs;
};

my $_build_links = sub {
   return $_to_array_of_hash->( $_[ 0 ]->_links, 'name', 'url' );
};

my $_build_user_home = sub {
   my $appldir = $_[ 0 ]->appldir; my $verdir = $appldir->basename;

   return $verdir =~ m{ \A v \d+ \. \d+ p (\d+) \z }msx
        ? $appldir->dirname : $appldir;
};

# Public attributes
has 'assets'          => is => 'ro',   isa => NonEmptySimpleStr,
   default            => 'assets/',

has 'author'          => is => 'ro',   isa => NonEmptySimpleStr,
   default            => 'anon';

has 'cdn'             => is => 'ro',   isa => SimpleStr, default => NUL;

has 'cdnjs'           => is => 'lazy', isa => HashRef,
   builder            => $_build_cdnjs, init_arg => undef;

has 'components'      => is => 'ro',   isa => HashRef, builder => sub { {} };

has 'compress_css'    => is => 'ro',   isa => Bool, default => TRUE;

has 'coverage_token'  => is => 'lazy', isa => $SECRET, coerce => TRUE,
   builder            => sub { '~/.ssh/coverage_token' };

has 'css'             => is => 'ro',   isa => NonEmptySimpleStr,
   default            => 'css/';

has 'data_mtime'      => is => 'lazy', isa => Path, coerce => TRUE,
   builder            => sub { $_[ 0 ]->datadir->catfile( '.mtime' ) };

has 'default_view'    => is => 'ro',   isa => SimpleStr, default => 'html';

has 'deflate_types'   => is => 'ro',   isa => ArrayRef[NonEmptySimpleStr],
   builder            => sub {
      [ qw( text/css text/html text/javascript application/javascript ) ] };

has 'description'     => is => 'ro',   isa => SimpleStr,
   default            => 'Server Test Coverage Statistics';

has 'font'            => is => 'ro',   isa => SimpleStr, default => NUL;

has 'help_url'        => is => 'ro',   isa => SimpleStr, default => 'help';

has 'homepage'        => is => 'ro',   isa => SimpleStr, default => 'report';

has 'images'          => is => 'ro',   isa => NonEmptySimpleStr,
   default            => 'img/';

has 'js'              => is => 'ro',   isa => NonEmptySimpleStr,
   default            => 'js/';

has 'jslibs'          => is => 'ro',   isa => ArrayRef, builder => sub { [] };

has 'keywords'        => is => 'ro',   isa => SimpleStr, default => NUL;

has 'languages'       => is => 'lazy', isa => ArrayRef[NonEmptySimpleStr],
   builder            => sub {
      [ map { (split m{ _ }mx, $_)[ 0 ] } @{ $_[ 0 ]->locales } ] },
   init_arg           => undef;

has 'layout'          => is => 'ro',   isa => NonEmptySimpleStr,
   default            => 'standard';

has 'less'            => is => 'ro',   isa => NonEmptySimpleStr,
   default            => 'less/';

has 'less_files'      => is => 'ro',   isa => ArrayRef[NonEmptySimpleStr],
   builder            => sub { [ qw( blue editor green navy red ) ] };

has 'links'           => is => 'lazy', isa => ArrayRef[HashRef],
   builder            => $_build_links, init_arg => undef;

has 'max_asset_size'  => is => 'ro',   isa => PositiveInt, default => 4_194_304;

has 'max_messages'    => is => 'ro',   isa => NonZeroPositiveInt, default => 3;

has 'max_sess_time'   => is => 'ro',   isa => PositiveInt, default => 3_600;

has 'mount_point'     => is => 'ro',   isa => NonEmptySimpleStr,
   default            => '/coverage';

has 'no_index'        => is => 'ro',   isa => ArrayRef[NonEmptySimpleStr],
   builder            => sub {
                         [ qw( \.git$ \.htpasswd$ \.json$ \.mtime$ \.svn$ ) ] };

has 'owner'           => is => 'lazy', isa => NonEmptySimpleStr,
   builder            => sub { $_[ 0 ]->prefix };

has 'port'            => is => 'lazy', isa => NonZeroPositiveInt,
   default            => 2015;

has 'repo_url'        => is => 'ro',   isa => SimpleStr, default => NUL;

has 'request_roles'   => is => 'ro',   isa => ArrayRef[NonEmptySimpleStr],
   builder            => sub { [ 'L10N', 'Session', 'JSON' ] };

has 'scrubber'        => is => 'ro',   isa => Str,
   default            => '[^ +\-\./0-9@A-Z\\_a-z~]';

has 'secret'          => is => 'lazy', isa => $SECRET, coerce => TRUE,
   builder            => sub { 'hostname' };

has 'serve_as_static' => is => 'ro',   isa => NonEmptySimpleStr,
   default            => 'css | favicon.ico | img | js | less';

has 'server'          => is => 'ro',   isa => NonEmptySimpleStr,
   default            => 'Starman';

has 'session_attr'    => is => 'lazy', isa => HashRef[ArrayRef],
   builder            => sub { {
      query           => [ SimpleStr | Undef                ],
      skin            => [ NonEmptySimpleStr, $_[ 0 ]->skin ],
      theme           => [ NonEmptySimpleStr, 'green'       ],
      use_flags       => [ Bool,              TRUE          ], } };

has 'skin'            => is => 'ro',   isa => NonEmptySimpleStr,
   default            => 'default';

has 'stash_attr'      => is => 'lazy', isa => HashRef[ArrayRef],
   builder            => sub { {
      config          => [ qw( author description keywords template ) ],
      links           => [ qw( css help_url homepage images js ) ],
      request         => [ qw( authenticated host language username ) ],
      session         => [ sort keys %{ $_[ 0 ]->session_attr } ], } };

has 'template'        => is => 'ro',   isa => ArrayRef[NonEmptySimpleStr],
   default            => sub { [ 'report', 'report' ] };

has 'title'           => is => 'ro',   isa => NonEmptySimpleStr,
   default            => 'Coverage Statistics';

has 'user'            => is => 'ro',   isa => SimpleStr, default => NUL;

has 'user_attributes' => is => 'ro',   isa => HashRef, builder => sub { {
   path               => $_[ 0 ]->ctrldir->catfile( 'users.json' ), } };

has 'user_home'       => is => 'lazy', isa => Path, coerce => TRUE,
   builder            => $_build_user_home;

# Private attributes
has '_links'          => is => 'ro',   isa => HashRef,
   builder            => sub { {} }, init_arg => 'links';

package # Hide from indexer
   Coverage::Server::_Secret;

use File::DataClass::Constants qw( TRUE );
use File::DataClass::IO;
use File::DataClass::Types     qw( NonEmptySimpleStr );
use Sys::Hostname              qw( hostname );
use Moo;

use namespace::clean -except => [ 'hostname', 'meta' ];
use overload '""' => sub { $_[ 0 ]->evaluate }, fallback => 1;

has 'value' => is => 'ro', isa => NonEmptySimpleStr, required => TRUE;

sub evaluate {
   my $v = $_[ 0 ]->value; my $file;

   return -x $v                                ? qx( $v )
        : ($file = io( $v ) and $file->exists) ? $file->all
        : exists $ENV{ $v }                    ? $ENV{ $v }
                                               : eval $v;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Coverage::Server::Config - Defines the configuration file options and their defaults

=head1 Synopsis

   use Class::Usul;

   my $usul = Class::Usul->new( config_class => 'Coverage::Server::Config' );

   my $author = $usul->config->author;

=head1 Description

Each of the attributes defined here, plus the ones inherited from
L<Class::Usul::Config::Programs>, can have their default value overridden
by the value in the configuration file

=head1 Configuration and Environment

The configuration file is, by default, in JSON format

It is found by calling the L<find_apphome|Class::Usul::Functions/find_apphome>
function

Defines the following attributes;

=over 3

=item C<assets>

A non empty simple string that defaults to F<assets/>. Relative URI path
that locates the assets files uploaded by users

=item C<assetdir>

Defaults to F<var/root/docs/assets>. Path object for the directory
containing user uploaded files

=item C<auth_roles>

The list of roles applicable to authorisation. Defaults to C<admin>,
C<editor>, and C<user>

=item C<author>

A non empty simple string that defaults to C<anon>. The HTML meta attributes
author value

=item C<blank_template>

Name of the template file to use when creating new markdown files

=item C<brand>

A simple string that defaults to null. The name of the image file used
on the splash screen to represent the application

=item C<cdn>

A simple string containing the URI prefix for the content delivery network

=item C<cdnjs>

A hash reference of URIs for JavaScript libraries stored on the
content delivery network. Created by prepending L</cdn> to L</jslibs>

=item C<colours>

A lazily evaluated array reference of hashes created automatically from the
hash reference in the configuration file. Each hash has a single
key / value pair, the colour name and it's hash value. If specified
creates a custom colour scheme for the project

=item C<components>

A hash reference containing component specific configuration options. Keyed
by component classname with the leading application class removed. e.g.

   $self->config->components->{ 'Controller::Root' };

=item C<compress_css>

Boolean default to true. Should the C<make_css> method compress it's output

=item C<css>

A non empty simple string that defaults to F<css/>. Relative URI path
that locates the static CSS files

=item C<default_view>

Simple string that default to C<html>. The moniker of the view that will be
used by default to render the response

=item C<deflate_types>

An array reference of non empty simple strings. The list of mime types to
deflate in L<Plack> middleware

=item C<description>

A simple string that defaults to null. The HTML meta attributes description
value

=item C<font>

A simple string that defaults to null. The default font used to
display text headings

=item C<help_url>

A simple string that defaults to C<pod>. The partial URI path which locates
this POD when rendered as HTML and served by this application

=item C<homepage>

A non empty simple string which defaults to C<report>. The partial URI of
the applications home page

=item C<images>

A non empty simple string that defaults to F<img/>. Relative URI path that
locates the static image files

=item C<js>

A non empty simple string that defaults to F<js/>. Relative URI path that
locates the static JavaScript files

=item C<jslibs>

An array reference of tuples. Each tuple consists of a library and a partial
URI path. Default to an empty list so this is usually set from the
configuration file

=item C<keywords>

A simple string that defaults to null. The HTML meta attributes keyword
list value

=item C<languages>

A array reference of string derived from the list of configuration locales
The value is constructed on demand and has no initial argument

=item C<layout>

A non empty simple string that defaults to F<standard>. The name of the
L<Template::Toolkit> template used to render the HTML response page. The
template will be wrapped by F<wrapper.tt>

=item C<less>

A non empty simple string that defaults to F<less/>. Relative URI path that
locates the static Less files

=item C<less_files>

The list of predefined colour schemes and feature specific less files

=item C<links>

A lazily evaluated array reference of hashes created automatically from the
hash reference in the configuration file. Each hash has a single
key / value pair, the link name and it's URI. The links are displayed in
the navigation panel and the footer in the default templates

=item C<max_asset_size>

Integer defaults to 4Mb. Maximum size in bytes of the file upload

=item C<max_messages>

Non zero positive integer defaults to 3. The maximum number of messages to
store in the session between requests

=item C<max_sess_time>

Time in seconds before a session expires. Defaults to 15 minutes

=item C<mount_point>

A non empty simple string that defaults to F</>. The root of the URI on
which the application is mounted

=item C<no_index>

An array reference that defaults to C<[ .git .svn cgi-bin doh.json ]>. List of
files and directories under the document root to ignore

=item C<owner>

A non empty simple string that defaults to the configuration C<prefix>
attribute. Name of the user and group that should own all files and
directories in the application when installed

=item C<port>

A lazily evaluated non zero positive integer that defaults to 8085. This
is the port number that the documentation server will listen on by default
when started by the control daemon

=item C<request_roles>

Defaults to C<L10N>, C<Session>, and C<JSON>. The list of roles to apply to
the default request base class

=item C<repo_url>

A simple string that defaults to null. The URI of the source code repository
for this project

=item C<scrubber>

A string used as a character class in a regular expression. These character
are scrubber from user input so they cannot appear in any user supplied
pathnames or query terms. Defaults to C<[;\$\`&\r\n]>

=item C<secret>

Used to encrypt the session cookie

=item C<serve_as_static>

A non empty simple string which defaults to
C<css | favicon.ico | img | js | less>. Selects the resources that are served
by L<Plack::Middleware::Static>

=item C<server>

A non empty simple string that defaults to C<Starman>. The L<Plack> engine
name to load when the documentation server is started in production mode

=item C<session_attr>

A hash reference of array references. These attributes are added to the ones
in L<Web::ComposableRequest::Session> to created the session class. The hash
key is the attribute name and the tuple consists of a type and a optional
default value. The default list of attributes is;

=over 3

=item C<query>

Default search string

=item C<theme>

A non empty simple string that defaults to C<green>. The name of the
default colour scheme

=item C<use_flags>

Boolean which defaults to C<TRUE>. Display the language code, which is
derived from browsers accept language header value, as a national flag. If
false display as text

=back

=item C<skin>

A non empty simple string that defaults to C<default>. The name of the default
skin used to theme the appearance of the application

=item C<stash_attr>

A hash reference of array references. The keys indicate a data source and the
values are lists of attribute names. The values of the named attributes are
copied into the stash. Defines the following keys and values;

=over 3

=item C<config>

The list of configuration attributes whose values are copied to the C<page>
hash reference in the stash

=item C<links>

An array reference that defaults to C<[ assets css help_url images less js ]>.
The application pre-calculates URIs for these static directories for use
in the HTML templates

=item C<request>

The list of request attributes whose values are copied to the C<page> hash
reference in the stash

=item C<session>

An array reference that defaults to the keys of the L</session_attr> hash
reference. List of attributes that can be specified as query parameters in
URIs. Their values are persisted between requests stored in the session store

=back

=item C<template>

If the selected L<Template::Toolkit> layout is F<standard> then this
attribute selects which left and right columns templates are rendered

=item C<title>

A non empty simple string that defaults to C<Documentation>. The documentation
project's title as displayed in the title bar of all pages

=item C<user>

Simple string that defaults to null. If set the daemon process will change
to running as this user when it forks into the background

=item C<user_attributes>

Defines these attributes;

=over 3

=item C<load_factor>

Defaults to 14. A non zero positive integer passed to the C<bcrypt> function

=item C<min_pass_len>

Defaults to 8. The minimum acceptable length for a password

=item C<path>

Defaults to F<var/root/docs/users.json>. A file object which contains the
users and their profile used by the application

=back

=item C<user_home>

The home directory of the user who owns the files and directories in the
the application

=back

=head1 Subroutines/Methods

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<File::DataClass>

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
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
