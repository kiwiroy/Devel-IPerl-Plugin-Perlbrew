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

can_ok $iperl, qw{perlbrew perlbrew_list perlbrew_list_modules};

is $iperl->perlbrew(), 0, 'no library for app::perlbrew';

my $save = $ENV{PERLBREW_ROOT};

is $iperl->perlbrew('random1'), 1, 'here';
is $iperl->perlbrew('random2'), 1, 'here';

is $ENV{PERLBREW_ROOT}, $save, 'no change';
is $ENV{PERLBREW_HOME}, '/tmp', 'set';

TODO: {
  local $TODO = "check if this is a good test - should prob check \@INC";
  is $ENV{PERL5LIB}, '/tmp/perl5', 'improve this';
}

my $plugin = new_ok('Devel::IPerl::Plugin::Perlbrew');
is $plugin->name, undef, 'empty default';
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
# constructor tests
$plugin = new_ok('Devel::IPerl::Plugin::Perlbrew', [name => 'foobar']);
$plugin->new(name => 'foo')->new({name => 'bar'})->brew;

# _make_name tests check various constraints
(my $current_perl = $^X) =~ s{.*/perls/([^/]+)/bin/perl}{$1};
is $plugin->_make_name('foo'), join('@', $ENV{PERLBREW_PERL}, 'foo'),
  'make name';
{
  local $ENV{PERLBREW_PERL} = 'perl-5.24.3';
  is $plugin->_make_name('bar'), 'perl-5.24.3@bar', 'make name';
  is $plugin->_make_name('perl-5.26.1@bar'), 'perl-5.24.3@bar', 'make name';
  delete $ENV{PERLBREW_PERL};
  ## default to directory
  (local $^X = $^X) =~ s{perls/([^/]+)/bin}{perls/perl-alias/bin};
  is $plugin->_make_name('bar'), 'perl-alias@bar', 'make name';
  is $plugin->_make_name('perl-5.26.1@bar'), 'perl-alias@bar', 'make name';
  ## default to perl version
  $^X =~ s{perls/([^/]+)/bin}{p/perl-alias/bin};
  (my $version =~ $^V->normal) =~ s{^v}{perl-};
  is $plugin->_make_name('bar'), join('@', $version, 'bar'), 'make name';
  is $plugin->_make_name('perl-5.26.1@bar'), join('@', $version, 'bar'),
    'make name';
}

is $iperl->perlbrew_list, 0, 'list';

is $iperl->perlbrew_list_modules, 1, 'list_modules';

done_testing;
