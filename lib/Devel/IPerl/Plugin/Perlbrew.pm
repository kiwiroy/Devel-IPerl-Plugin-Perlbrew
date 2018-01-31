package Devel::IPerl::Plugin::Perlbrew;

use strict;
use warnings;
use feature 'say';

our $VERSION = '0.01';

sub brew {
  my $self = shift;
  my %env = %{$self->env || {}};
  for my $var(sort grep { ! /^PERL5LIB$/ } keys %env) {
    say STDERR join " = ", $var, $env{$var};
    $ENV{$var} = $env{$var};
  }
  say STDERR join " = ", 'PERL5LIB', $env{'PERL5LIB'};
  eval "use lib split ':', q[$env{PERL5LIB}];" if $env{PERL5LIB};
  return $self;
}

sub env  { return $_[0]{env}  if @_ == 1; $_[0]{env}  = $_[1]; $_[0]; }

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub name { return $_[0]{name} if @_ == 1; $_[0]{name} = $_[1]; $_[0]; }

sub register {
  my ($class, $iperl) = @_;

  for my $name (qw{perlbrew}) {
    my $last = $class->new->name('@@@'); ## impossible name

    $iperl->helper($name => sub {
      my ($ip, $lib, $ret) = (shift, shift, 0);
      return $ret if not defined $lib;

      eval { require App::perlbrew; 1; };
      return $ret if $@;

      my $new = $class->new->name($class->_make_name($lib));
      if ($last->name ne $new->name) {
        my $pb = App::perlbrew->new();
        $new->env({ $pb->perlbrew_env($new->name) });
        $last = undef;
        $last = $new->brew;
      }
      return $new->success;
    });
  }
  return 1;
}

sub spoil {
  my $self = shift;
  my %env = %{$self->{env} || {}};
  eval "no lib split ':', q[$env{PERL5LIB}];" if $env{PERL5LIB};
  return $self;
}

sub success { scalar(keys %{$_[0]->{env}}) ? 1 : 0; }

sub _from_binary_path {
  warn $^X;
  if ($^X =~ m{\/(perl-5\.\d\d\.\d)\/}) { return $1; }
}

sub _make_name {
  my ($class, $lib) = @_;
  my ($p, $l) = split /\@/, ($lib =~ /\@/ ? $lib : "\@$lib");
  $p = $ENV{PERLBREW_PERL} || _from_binary_path() || $p;
  return join '@', $p, $l
}

sub DESTROY {
  my $self = shift;
  # warn "DESTROY $self @$self{name}\n";
  $self->spoil;
}

1;
