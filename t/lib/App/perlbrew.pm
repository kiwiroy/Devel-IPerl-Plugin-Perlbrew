package ## no pause
  App::perlbrew;
use strict;
use warnings;
use File::Spec::Functions 'catdir';
use FindBin;

our $PERL5LIB = catdir($FindBin::Bin, 'lib', 'perl5');

sub current_perl { return $ENV{PERLBREW_PERL} || 'perl-5.26.0'; }

sub new { bless {}, $_[0]; }

sub perlbrew_env {
  return (
    PERLBREW_ROOT => $ENV{PERLBREW_ROOT},
    PERLBREW_HOME => '/tmp',
    PERL5LIB => $PERL5LIB
  );
}
sub run_command {
  my ($self, $cmd) = (shift, shift);
  my $code = $self->can("run_command_$cmd");
  $code->(@_) if $code;
}

sub run_command_list {
  return 0;
}

sub run_command_list_modules {
  return 1;
}

1;
