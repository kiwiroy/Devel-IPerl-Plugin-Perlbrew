use strict;
use warnings;
BEGIN {
  $ENV{IPERL_PLUGIN_PERLBREW_DEBUG} = $ENV{TEST_VERBOSE};
  $ENV{IPERL_PLUGIN_PERLBREW_CLASS} = 'Test::App::perlbrew';
}
use Test::More;
use Devel::IPerl;
use IPerl;
use lib 't/lib';

my $domain = $ENV{PERLBREW_HOME} || '';
my $iperl  = new_ok('IPerl');
ok $iperl->load_plugin('Perlbrew');
can_ok $iperl, qw{perlbrew perlbrew_domain perlbrew_lib_create perlbrew_list
                  perlbrew_list_modules};

#
# Test the internal plugin interface first
#
my $plugin = new_ok('Devel::IPerl::Plugin::Perlbrew');
is $plugin->name, undef, 'empty default';
is $plugin->name('perl-5.26.0@random'), $plugin, 'chaining';
is $plugin->name, 'perl-5.26.0@random', 'set';
is $plugin->unload, undef, 'empty';
is $plugin->unload(1), $plugin, 'chaining';
is $plugin->unload, 1, 'set';
is $plugin->unload(0)->unload, 0, 'unset';

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
  $plugin->env($env_set);
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
{
  local $ENV{PERLBREW_PERL} = 'perl-alias';
  (local $^X = $^X) =~ s{perls/([^/]+)/bin}{perls/perl-alias/bin};

  is $plugin->_make_name('alias@example'), 'perl-alias@example',
    'perl match current with existing lib';
  is $plugin->_make_name('alias@lib'),     'perl-alias@lib',
    'perl match current with new lib';
  is $plugin->_make_name('5.26.0@random'), 'perl-5.26.0@random',
    'perl with same version, and existing lib';
  ## the current perl is preferred when neither have the library.
  is $plugin->_make_name('5.26.0@example'), 'perl-alias@example',
    'perl with same version, and new lib - these cannot be created';
  ## cannot switch to this library free compatible perl
  is $plugin->_make_name('5.26.0'),        'perl-alias',
    'installed perl with no lib - cannot be accessed';

  is $plugin->_make_name('5.24.0'),        'perl-alias',
    'non installed perl with no lib';
  is $plugin->_make_name('alias'),         'perl-alias',
    'shortened name with no lib';
  is $plugin->_make_name('alias@random'),  'perl-alias@random',  '';
  is $plugin->_make_name('5.26.0@random'), 'perl-5.26.0@random', '';

  # some helpful versions
  is $plugin->_make_name('foo-bar-baz'),  'perl-alias@foo-bar-baz',
    'no perl, just a libray (new), without @';
  is $plugin->_make_name('foo'),          'perl-alias@foo',
    'no perl, just a libray, without @';
  is $plugin->_make_name('@foo'),          'perl-alias@foo',
    'no perl, just a libray, explicitly with @';
  is $plugin->_make_name('bad@'),          'perl-alias',
    'trailing @ is in no way supported';
  is $plugin->_make_name('rad@rad@rad'),   'perl-alias@rad',
    'multiple @ will take the element at position 1';
}

{
  local $ENV{PERLBREW_PERL} = 'perl-5.8.9';
  (local $^X = $^X) =~ s{perls/([^/]+)/bin}{perls/perl-5.8.9/bin};
  is $plugin->_make_name('5.8.9@random'),     'perl-5.8.9@random',
    'perl match current with new lib';
  is $plugin->_make_name('5.8.8@archive'),    'perl-5.8.9@archive',
    'perl match current with new lib';
  is $plugin->_make_name('5.26.0@random'),    'perl-5.8.9@random',
    'perl with different version, and existing lib';
  is $plugin->_make_name('5.26.0'),        'perl-5.8.9',
    'installed perl with no lib - cannot be accessed';

}

{
  local $ENV{PERLBREW_PERL} = 'perl-5.24.3';
  (local $^X = $^X) =~ s{perls/([^/]+)/bin}{perls/perl-5.24.3/bin};
  is $plugin->_make_name('bar'), 'perl-5.24.3@bar', 'make name';
  is $plugin->_make_name('perl-5.26.1@bar'), 'perl-5.24.3@bar', 'make name';
  delete $ENV{PERLBREW_PERL};
  ## default to directory
  (local $^X = $^X) =~ s{perls/([^/]+)/bin}{perls/perl-alias/bin};
  is $plugin->_make_name('bar'), 'perl-alias@bar', 'make name';
  is $plugin->_make_name('perl-5.26.1@bar'), 'perl-alias@bar', 'make name';
  is $plugin->_make_name('perl-alias'), 'perl-alias',
    'non-numeric "current" perl';
  ## default to perl version
  $^X =~ s{perls/([^/]+)/bin}{p/perl-alias/bin};
  (my $version = $^V->normal) =~ s{^v}{perl-};
  is $plugin->_make_name('bar'), join('@', $version, 'bar'), 'make name';
  is $plugin->_make_name('perl-5.26.1@bar'), join('@', $version, 'bar'),
    'make name';
}

#
# Now to working on the functionality of plugin functions
#
is $iperl->perlbrew(), -1, 'no library for app::perlbrew';

my $save = $ENV{PERLBREW_ROOT};

is $iperl->perlbrew('random1'), 1, 'here';
is $iperl->perlbrew('random2'), 1, 'here';
is $iperl->perlbrew('random2'), 0, 'here';

is $ENV{PERLBREW_ROOT}, $save, 'no change';
is $ENV{PERLBREW_HOME}, '/tmp', 'set';

is $iperl->perlbrew_domain, $domain, 'domain from register';
is $iperl->perlbrew_domain('/tmp'), '/tmp', 'domain set';

my @added = grep { m{^\Q$Test::App::perlbrew::PERL5LIB\E$} } @INC;
is @added, 1, "contains path '$Test::App::perlbrew::PERL5LIB'";

is $iperl->perlbrew_lib_create(), -1, 'no lib in lib_create';
is $iperl->perlbrew_lib_create('special'), 1, 'lib_create';
is $iperl->perlbrew_lib_create('test-library'), 0,
  'lib_create dies in App::perlbrew';

is $iperl->perlbrew_list, 0, 'list';

is $iperl->perlbrew_list_modules, 1, 'list_modules';

#
# test the unloading feature.
#
is $iperl->perlbrew('random1', 1), 1, 'here';
@added = grep { m{^\Q$Test::App::perlbrew::PERL5LIB\E$} } @INC;
is @added, 1, "contains path '$Test::App::perlbrew::PERL5LIB'";

eval "use ACME::NotThere; 1;";
is $@, '', 'no errors';

is $iperl->perlbrew('random2', 1), 1, 'here';

is $INC{'ACME/NotThere.pm'}, undef, 'not in %INC';
eval "ACME::NotThere->heres_johnny;";
like $@, qr/heres_johnny/, 'nope';

# use Data::Dumper;
# diag Dumper [ Test::App::perlbrew->installed_perls ] ;
done_testing;
