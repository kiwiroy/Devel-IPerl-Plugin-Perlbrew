## no critic(NamingConventions::Capitalization)
package ## no pause
  Test::App::perlbrew;
use strict;
use warnings;
use File::Spec::Functions 'catdir';
use FindBin;

our $PERL5LIB = catdir($FindBin::Bin, 'lib', 'perl5');

sub current_perl { return $ENV{PERLBREW_PERL} || 'perl-5.26.0'; }

sub new { bless {}, $_[0]; }

sub home {
}
sub comparable_perl_version {
  shift;
  require App::perlbrew;
  (
    App::perlbrew->comparable_perl_version(@_)
  );
}
sub installed_perls {
  my $self = shift;
  my @result;
  (my $version = $^V->normal) =~ s{^v}{perl-};
  my %perlset = (
    $version      => [$self->comparable_perl_version($version)],
    'perl-5.26.0' => [5_260_000, qw{foo bar random random1 random2}],
    'perl-5.24.3' => [5_240_300, qw{bar}],
    'perl-alias'  => [5_260_000, qw{example}],
    'perl-5.8.9'  => [5_080_900, qw{archived}],
  );
  for my $perl(keys %perlset){
    my $inst = {
      name => $perl, comparable_version => shift(@{$perlset{$perl}}), libs => []
    };
    for my $lib(@{$perlset{$perl}}) {
      push @{$inst->{libs}}, {
        name => join('@', $perl, $lib), lib_name => $lib, perl_name => $perl
      };
    }
    push @result, $inst;
  }
# use Data::Dumper;
#  warn Dumper \@result;
  return @result;
}

sub perlbrew_env {
  return (
    PERLBREW_ROOT => $ENV{PERLBREW_ROOT},
    PERLBREW_HOME => '/tmp',
#    PERL_LOCAL_LIB_ROOT => $FindBin::Bin,
#    PERL_MM_OPT => "INSTALL_BASE=$FindBin::Bin",
#    PERL_MB_OPT => "--install_base $FindBin::Bin",
    PERL5LIB => $PERL5LIB,
  );
}

sub resolve_installation_name {
  my ($self, $name) = @_;
  my ($perl, $lib)  = split /\@/, $name, 2;
  my @installed     = $self->installed_perls;
  if (0 == grep { $_->{name} eq $perl } @installed) {
    if (grep { $_->{name} eq "perl-$perl" } @installed) {
      $perl = "perl-$perl";
    } else {
      return undef
    }
  }
  return ($perl, $lib);
}

sub run_command {
  my ($self, $cmd) = (shift, shift);
  my $code = $self->can("run_command_$cmd");
  $code->(@_) if $code;
}

sub run_command_lib_create {
  my ($self, $name) = @_;
  die "already exists" if $name =~ m/test-library$/;
  return ;
}

sub run_command_list {
  return 0;
}

sub run_command_list_modules {
  return 1;
}

1;
