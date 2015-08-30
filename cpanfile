requires "Class::Usul" => "v0.65.0";
requires "Exporter::Tiny" => "0.042";
requires "File::DataClass" => "v0.66.0";
requires "HTML::FormWidgets" => "v0.23.0";
requires "HTTP::Message" => "6.06";
requires "JSON::MaybeXS" => "1.003005";
requires "Moo" => "2.000001";
requires "Plack" => "1.0036";
requires "SVG" => "2.64";
requires "Template" => "2.26";
requires "Try::Tiny" => "0.22";
requires "Type::Tiny" => "1.000005";
requires "Unexpected" => "v0.39.0";
requires "Web::Components" => "v0.4.0";
requires "Web::Simple" => "0.030";
requires "local::lib" => "2.000015";
requires "namespace::autoclean" => "0.26";
requires "namespace::clean" => "0.25";
requires "perl" => "5.010001";
requires "strictures" => "2.000000";

on 'build' => sub {
  requires "Module::Build" => "0.4004";
  requires "version" => "0.88";
};

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "Module::Build" => "0.4004";
  requires "Module::Metadata" => "0";
  requires "Sys::Hostname" => "0";
  requires "Test::Requires" => "0.06";
  requires "version" => "0.88";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "Module::Build" => "0.4004";
  requires "version" => "0.88";
};
