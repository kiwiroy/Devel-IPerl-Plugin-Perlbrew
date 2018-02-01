use strict;
use warnings;
BEGIN {
  $ENV{IPERL_PLUGIN_PERLBREW_DEBUG} = 1;
}
use Test::More;
use Devel::IPerl;
use IPerl;
use lib 't/lib';

my $iperl = new_ok('IPerl');

ok $iperl->load_plugin('Perlbrew');

is $iperl->perlbrew(), 0, 'no library for app::perlbrew';

my $save = $ENV{PERLBREW_ROOT};

is $iperl->perlbrew('random'), 1, 'here';

is $ENV{PERLBREW_ROOT}, $save, 'no change';
is $ENV{PERLBREW_HOME}, '/tmp', 'set';

TODO: {
  local $TODO = "check if this is a good test - should prob check \@INC";
  is $ENV{PERL5LIB}, '/tmp/perl5', 'improve this';
}

my $plugin = new_ok('Devel::IPerl::Plugin::Perlbrew');
is $plugin->name('perl-5.26.0@random'), $plugin, 'chaining';
is $plugin->name, 'perl-5.26.0@random', 'set';

my $env_set = {
  PERLBREW_TEST_VAR => 1,
  TEST_THIS => 1,
  PERLBREW_TEST_MODE => 'develop',
};
is $plugin->env($env_set), $plugin, 'chaining';
is_deeply $plugin->env, $env_set, 'set';
is $ENV{PERLBREW_TEST_VAR}, undef, 'not set';
is $ENV{PERLBREW_TEST_MODE}, undef, 'not set';
is $ENV{TEST_THIS}, undef, 'not set';

{
  diag "Brew 1" if $ENV{IPERL_PLUGIN_PERLBREW_DEBUG};
  local %ENV = %ENV;
  $ENV{PERLBREW_TEST_MODE} = 'production';
  $plugin->brew;
  is $ENV{PERLBREW_TEST_VAR}, 1, 'now set';
  is $ENV{PERLBREW_TEST_MODE}, 'develop', 'mode now set';
  is $ENV{TEST_THIS}, undef, 'not set';
  $plugin->spoil;
  is $ENV{PERLBREW_TEST_VAR}, undef, 'not set';
  is $ENV{PERLBREW_TEST_MODE}, 'production', 'mode reverted';
}

{
  diag "Brew 2" if $ENV{IPERL_PLUGIN_PERLBREW_DEBUG};
  local %ENV = %ENV;
  $ENV{PERLBREW_TEST_MODE} = 'production';
  $plugin->brew;
  is $ENV{PERLBREW_TEST_VAR}, 1, 'now set';
  is $ENV{PERLBREW_TEST_MODE}, 'develop', 'mode now set';
  is $ENV{TEST_THIS}, undef, 'not set';
  undef $plugin; # this should also call spoil.
  is $ENV{PERLBREW_TEST_VAR}, undef, 'not set';
  is $ENV{PERLBREW_TEST_MODE}, 'production', 'mode reverted';
}

is $iperl->perlbrew_list, 0, 'list';

done_testing;
