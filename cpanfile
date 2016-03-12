requires "Catalyst::Controller::HTML::FormFu" => "0";
requires "Catalyst::Model::DBIC::Schema" => "0";
requires "CatalystX::InjectComponent" => "0";
requires "File::ShareDir" => "0";
requires "JSON::MaybeXS" => "0";
requires "List::UtilsBy" => "0";
requires "Moose" => "0";
requires "Moose::Role" => "0";
requires "OpusVL::AppKit" => "0";
requires "OpusVL::SysParams" => "0";
requires "Try::Tiny" => "0";
requires "base" => "0";
requires "namespace::autoclean" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Catalyst::ScriptRunner" => "0";
  requires "Catalyst::Test" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "FindBin" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Pod" => "1.14";
  requires "Test::Pod::Coverage" => "1.04";
  requires "Test::WWW::Mechanize::Catalyst" => "0";
  requires "blib" => "1.01";
  requires "lib" => "0";
  requires "ok" => "0";
  requires "perl" => "5.006";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::Pod" => "1.41";
};
