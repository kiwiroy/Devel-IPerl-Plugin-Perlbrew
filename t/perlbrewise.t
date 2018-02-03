use strict;
use warnings;
use Test::More;
use Path::Class qw{dir};
use JSON::MaybeXS qw(decode_json);

## installer script
require './scripts/perlbrewise-spec';
{
  no warnings 'once';
  ## setting this subverts the writing to kernel.json in install location
  $Devel::IPerl::Plugin::Perlbrew::Install::JUPYTER =
    join ' ', $^X, './t/jupyter';
}

my $class = 'Devel::IPerl::Plugin::Perlbrew::Install';

is $class->main(), 1, 'file does not exist';

my $target = $class->get_kernels_target_dir;
$target->mkpath;
my $kernel_file = dir($target)->file('kernel.json');

diag $kernel_file;

$kernel_file->spew(<<'EOF');
{
  "argv": [ "test" ]
}
EOF

is $class->main(), 0, 'now that file does exist';

is_deeply decode_json($kernel_file->slurp()), {
  argv => ["test"],
  env  => {
    map { $_ => $ENV{$_} }
      qw{PERLBREW_PATH PERLBREW_PERL PERLBREW_ROOT PERLBREW_VERSION PERLBREW_HOME}
  }
}, 'json all good';

$kernel_file->remove;

done_testing;
