package Coverage::Server::Controller::Root;

use Web::Simple;

with 'Web::Components::Role';

has '+moniker' => default => 'root';

sub dispatch_request {
   sub (GET  + /badge/* | /badge/**.* + ?*) { [ 'report', 'get_badge',   @_ ] },
   sub (GET  + /help    | /help/*     + ?*) { [ 'report', 'get_help',    @_ ] },
   sub (POST + /report/*              + ?*) { [ 'report', 'add_report',  @_ ] },
   sub (GET  + /report/*              + ?*) { [ 'report', 'get_latest',  @_ ] },
   sub (GET  + /report/**.*           + ?*) { [ 'report', 'get_content', @_ ] },
   sub (GET  + /report  | /report/    + ?*) { [ 'report', 'get_reports', @_ ] },
   sub (GET  + /index   | /           + ?*) { [ 'report', 'get_reports', @_ ] },
   sub (GET  + /**                    + ?*) { [ 'report', 'not_found',   @_ ] };
}

1;

__END__

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
