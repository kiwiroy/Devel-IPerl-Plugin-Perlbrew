package ## no pause
  App::perlbrew;
use strict;
use warnings;

sub new { bless {}, $_[0]; }

sub perlbrew_env {
  return (
    PERLBREW_ROOT => $ENV{PERLBREW_ROOT},
    PERLBREW_HOME => '/tmp',
    PERL5LIB => '/tmp/perl5'
  );
}

1;
