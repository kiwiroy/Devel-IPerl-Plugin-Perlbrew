package Devel::IPerl::Plugin::Perlbrew;

use strict;
use warnings;
use feature 'say';

use constant DEBUG => $ENV{IPERL_PLUGIN_PERLBREW_DEBUG} ? 1 : 0;

use constant PERLBREW_CLASS => $ENV{IPERL_PLUGIN_PERLBREW_CLASS}
  ? $ENV{IPERL_PLUGIN_PERLBREW_CLASS}
  : 'App::perlbrew';

use constant PERLBREW_INSTALLED => eval 'use '. PERLBREW_CLASS.'; 1' ? 1 : 0;

our $VERSION = '0.01';

sub brew {
  my $self = shift;
  my %env  = %{$self->env || {}};
  my %save = ();
  for my $var(_filtered_env_keys(\%env)) {
    say STDERR join " = ", $var, $env{$var} if DEBUG;
    $save{$var} = $ENV{$var} if exists $ENV{$var};
    $ENV{$var} = $env{$var};
  }
  if ($env{PERL5LIB}) {
    say STDERR join " = ", 'PERL5LIB', $env{'PERL5LIB'} if DEBUG;
    eval "use lib split ':', q[$env{PERL5LIB}];";
    warn $@ if $@;
  }
  return $self->saved(\%save);
}

sub env { return $_[0]{env}  if @_ == 1; $_[0]{env}  = $_[1]; $_[0]; }

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub name { return $_[0]{name} if @_ == 1; $_[0]{name} = $_[1]; $_[0]; }

sub register {
  my ($class, $iperl) = @_;

  for my $name (qw{perlbrew}) {
    my $current = $class->new->name('@@@'); ## impossible name

    $iperl->helper($name => sub {
      my ($ip, $lib, $ret) = (shift, shift, 0);
      return $ret if not defined $lib;
      return $ret if 0 == PERLBREW_INSTALLED;

      my $new = $class->new->name($class->_make_name($lib));
      if ($current->name ne $new->name) {
        my $pb = PERLBREW_CLASS->new();
        $new->env({ $pb->perlbrew_env($new->name) });
        $current = undef;
        $current = $new->brew;
      }
      return $new->success;
    });
  }

  for my $name (qw{list list_modules}) {
    $iperl->helper("perlbrew_$name" => sub {
      my ($ip, $ret) = (shift, 0);
      return $ret if 0 == PERLBREW_INSTALLED;
      my $pb = PERLBREW_CLASS->new();
      return $pb->run_command($name);
    });
  }
  return 1;
}

sub saved { return $_[0]{saved}  if @_ == 1; $_[0]{saved}  = $_[1]; $_[0]; }

sub spoil {
  my $self = shift;
  my %env  = %{$self->env || {}};
  my %save = %{$self->saved || {}};
  for my $var(_filtered_env_keys(\%env)) {
    if (exists $save{$var}) {
      say STDERR "revert ", join " = ", $var, $save{$var} if DEBUG;
      $ENV{$var} = $save{$var};
    } else {
      say STDERR "unset ", $var if DEBUG;
      delete $ENV{$var};
    }
  }
  if ($env{PERL5LIB}) {
    say STDERR join " = ", 'PERL5LIB', $env{'PERL5LIB'} if DEBUG;
    eval "no lib split ':', q[$env{PERL5LIB}];";
    warn $@ if $@;
  }
  return $self;
}

sub success { scalar(keys %{$_[0]->{env}}) ? 1 : 0; }

sub _filtered_env_keys {
  return (sort grep { m/^PERL/i && $_ ne "PERL5LIB" } keys %{+pop});
}

sub _from_binary_path {
  say STDERR $^X if DEBUG;
  if ($^X =~ m{/perls/([^/]+)/bin/perl}) { return $1; }
  (my $v = $^V->normal) =~ s/v/perl-/;
  return $v;
}

sub _make_name {
  my ($class, $lib) = @_;
  my ($p, $l) = split /\@/, ($lib =~ /\@/ ? $lib : "\@$lib");
  $p = $ENV{PERLBREW_PERL} || _from_binary_path();
  return join '@', $p, $l;
}

sub DESTROY {
  my $self = shift;
  say STDERR "DESTROY $self @$self{name}" if DEBUG;
  $self->spoil;
}

1;

=pod

=head1 NAME

Devel::IPerl::Plugin::Perlbrew - interact with L<perlbrew> in L<Jupyter|https://jupyter.org> IPerl kernel

=begin html

<!--- Travis --->
<a href="https://travis-ci.org/kiwiroy/Devel-IPerl-Plugin-Perlbrew">
  <img src="https://travis-ci.org/kiwiroy/Devel-IPerl-Plugin-Perlbrew.svg?branch=master"
       alt="Build Status" />
</a>

<!-- Kritika -->
<a href="https://kritika.io/users/kiwiroy/repos/6870682787977901/heads/master/">
  <img src="https://kritika.io/users/kiwiroy/repos/6870682787977901/heads/master/status.svg"
       alt="Kritika Analysis Status"/>
</a>

=end html

=head1 DESCRIPTION

Sometime analysis requires ...

  perlbrew lib create perl-5.26.0@reproducible
  perlbrew use perl-5.26.0@reproducible
  ## assuming a cpanfile
  cpanm --installdeps .

=head1 SYNOPSIS

  IPerl->load_plugin('Perlbrew') unless IPerl->can('perlbrew');
  IPerl->perlbrew_list();
  IPerl->perlbrew_list_modules();

  IPerl->perlbrew('perl-5.26.0@reproducible');

=head1 INSTALLATION AND REQUISITES

  ## install dependencies
  cpanm --installdeps --quiet .
  ## install
  cpanm .

If there are some issues with L<Devel::IPerl> installing refer to their
L<README.md|https://github.com/EntropyOrg/p5-Devel-IPerl>. The C<.travis.yml> in
this repository might provide sources of help.

L<App::perlbrew> is a requirement and it is B<suggested> that L<Devel::IPerl> is
deployed into a L<perlbrew> installed L<perl|perlbrew#COMMAND:-INSTALL> and use
the L</"perlbrew"> to switch L<library|perlbrew#COMMAND:-LIB>.

=head1 IPerl Interface Method

=head2 register

Called by C<<< IPerl->load_plugin('Perlbrew') >>>.

=head1 REGISTERED METHODS

=head2 perlbrew

  IPerl->perlbrew('perl-5.26.0@reproducible');

=head2 perlbrew_list

  IPerl->perlbrew_list;

This is identical to C<<< perlbrew list >>> and will output the same information.

=head2 perlbrew_list_modules

  IPerl->perlbrew_list_modules;

This is identical to C<<< perlbrew list_modules >>> and will output the same
information.

=head1 ENVIRONMENT VARIABLES

The following environment variables alter the behaviour of the plugin.

=over 4

=item IPERL_PLUGIN_PERLBREW_DEBUG

A logical to control how verbose the plugin is during its activities.

=item IPERL_PLUGIN_PERLBREW_CLASS

This defaults to L<App::prelbrew>

=back

=head1 INTERNAL INTERFACES

These are part of the internal interface and not designed for end user
consumption.

=head2 brew

  $plugin->brew;

Use the perlbrew library specified in L</"name">.

=head2 env

  $plugin->env({PERLBREW_ROOT => '/sw/perlbrew', ...});
  # {PERLBREW_ROOT => '/sw/perlbrew', ...}
  $plugin->env;

An accessor that stores the environment from L<App::perlbrew> for a subsequent
call to L</"brew">.

=head2 new

  my $plugin = Devel::IPerl::Plugin::Perlbrew->new();

Instantiate an object.

=head2 name

  $plugin->name('perl-5.26.0@reproducible');
  # perl-5.26.0@reproducible
  $plugin->name;

An accessor for the name of the perlbrew library.

=head2 saved

  $plugin->saved;

An accessor for the previous environment variables so they may be restored as
the L</"brew"> L</"spoil">s.

=head2 spoil

  $plugin->spoil;

When a L</"brew"> is finished with. This is called automatically during object
destruction.

=head2 success

  $plugin->success;

Was everything a success?

=cut
