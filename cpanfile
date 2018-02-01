## -*- mode: perl; -*-
# You can install this project with
# curl -L http://cpanmin.us | perl - https://github.com/hrards/devel-iperl-plugin-perlbrew/archive/master.tar.gz
requires "perl" => "5.10.0";

requires 'App::perlbrew';
requires 'Devel::IPerl' => "0.009";

test_requires "Test::More" => "0.88";


on develop => sub {
  requires "Devel::Cover";
  requires "Devel::Cover::Report::Kritika";
  requires 'Test::CPAN::Changes';
  requires "Test::Pod::Coverage";
  requires "Test::Pod";
  requires "Markdent" => "== 0.26";
  requires "Markdown::Pod" => "== 0.006";
};
