package POEx::MUD;
use strictures 1;

use Carp 'confess';
use Module::Runtime 'use_module';

sub import {
  my ($self, @modules) = @_;
  my $pkg = caller;

  my @failed;

  for my $mod (@modules) {
    my $c =
      "package $pkg; use POEx::MUD::$mod;";
    eval $c;
    if ($@) {
      warn $@;
      push @failed, $mod
    }
  }

  confess "Failed to import ".join ' ', @failed
    if @failed;

  1
}

sub new {
  my (undef, $module) = splice @_, 0, 2;
  confess "top-level new() expects a module name and optional args"
    unless $module;

  my $real = __PACKAGE__ .'::'. $module;
  use_module($real)->new(@_)
}

no warnings 'void';
q[
  <Gilded> 1. Need a professional drummer
   2. Look up Portnoy in a phonebook 
   3. Ask him to come over to the studio with a large kit
   4. avenj shows up with seven automatic rifles
];

__END__


=pod


=cut
