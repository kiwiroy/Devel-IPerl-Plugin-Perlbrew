# You can install this project with curl -L http://cpanmin.us | perl - https://github.com/hrards/devel-iperl-plugin-perlbrew/archive/master.tar.gz
requires "perl" => "5.10.0";

requires 'App::perlbrew';

test_requires "Test::More" => "0.88";


on develop => sub {

  requires "Devel::Cover";
  requires "Devel::Cover::Report::Kritika";
  requires 'Test::CPAN::Changes';
  requires "Test::Pod::Coverage";
  requires "Test::Pod";

};
