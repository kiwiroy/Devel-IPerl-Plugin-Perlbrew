package Devel::IPerl::Plugin::Perlbrew;

use strict;
use warnings;
use feature 'say';

our $VERSION = '0.01';

sub register {
  my ($self, $iperl) = @_;
  for my $name (qw{perlbrew}) {
    $iperl->helper($name => sub {
      my ($ip, $ret, %env) = (shift, 0);
      return $ret if 0 == @_;

      eval { require App::perlbrew; 1; };
      return $ret if $@;

      my $pb = App::perlbrew->new();
      %env = $pb->perlbrew_env(@_);
      for my $var(grep { ! /^PERL5LIB$/ } keys %env) {
        say STDERR join " = ", $var, $env{$var};
        $ENV{$var} = $env{$var};
      }
      eval "use lib split ':', q[$env{PERL5LIB}];" if $env{PERL5LIB};
      return scalar(keys %env) ? 1 : 0;
    });
  }
  return 1;
}

1;
