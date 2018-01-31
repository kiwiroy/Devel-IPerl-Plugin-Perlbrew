use strict;
use warnings;

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
is $ENV{PERL5LIB}, '/tmp/perl5', 'improve this';


done_testing;
