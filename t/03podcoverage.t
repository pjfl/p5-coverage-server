use strict;
use warnings;
use File::Spec::Functions qw( catdir updir );
use FindBin               qw( $Bin );
use lib               catdir( $Bin, updir, 'lib' );

use Test::More;

BEGIN {
   $ENV{AUTHOR_TESTING}
      or plan skip_all => 'POD coverage test only for developers';
}

use English qw( -no_match_vars );

eval "use Test::Pod::Coverage 1.04";

$EVAL_ERROR and plan skip_all => 'Test::Pod::Coverage 1.04 required';

my $opts = { also_private => [ qr{ \A (?: BUILDARGS | BUILD ) \z }mx ] };

pod_coverage_ok( 'Coverage::Server',         $opts );
pod_coverage_ok( 'Coverage::Server::CLI',    $opts );
pod_coverage_ok( 'Coverage::Server::Config', $opts );
pod_coverage_ok( 'Coverage::Server::Util',   $opts );

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
