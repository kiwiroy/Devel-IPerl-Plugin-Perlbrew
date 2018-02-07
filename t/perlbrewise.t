use strict;
use warnings;
use Test::More;
use File::Temp qw{tempdir};
use Path::Class qw{dir};
use JSON::MaybeXS qw(decode_json);

my $tmp =
  tempdir('devel-iperl-plugin-perlbrew-XXXXX', TMPDIR => 1, CLEANUP => 1 );

## installer script
require './scripts/perlbrewise-spec';
{
  no warnings 'once';
  ## setting this subverts the writing to kernel.json in install location
  $Devel::IPerl::Plugin::Perlbrew::Install::JUPYTER =
    join ' ', $^X, './t/jupyter', $tmp;
}

my $class = 'Devel::IPerl::Plugin::Perlbrew::Install';

is $class->main(), 1, 'file does not exist';

can_ok $class, qw{_all_variables_set};
if (my $all_vars = $class->can('_all_variables_set')) {
  local %ENV = %ENV;
  @ENV{qw{PERLBREW_HOME PERLBREW_PATH PERLBREW_PERL PERLBREW_ROOT PERLBREW_VERSION}} =
    qw{/home/user /sw/perlbrew/bin perl-5.26.0 /sw/perlbrew 0.78};
  my $spec = {
    env => {
      # purposely missing PERLBREW_PERL
      map { $_ => $ENV{$_} } qw{PERLBREW_HOME PERLBREW_PATH
                                PERLBREW_ROOT PERLBREW_VERSION}
    }
  };
  is $all_vars->({}), '', 'nothing set';
  is $all_vars->($spec), '', 'not all set';

  $spec->{env}{PERLBREW_PERL} = $ENV{PERLBREW_PERL};
  is $all_vars->($spec), 1, 'all set';

  $ENV{PERLBREW_VERSION} = "0.82";
  is $all_vars->($spec), '', 'version mismatch';

  $spec->{env}{PERLBREW_VERSION} = $ENV{PERLBREW_VERSION};
  is $all_vars->($spec), 1, 'version matches';

  delete $spec->{env}{PERLBREW_VERSION};
  is $all_vars->($spec), '', 'version mismatch';
}

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
