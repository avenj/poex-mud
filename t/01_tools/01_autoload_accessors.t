use Test::More; use Test::Exception;
use strict; use warnings qw/FATAL all/;

{
 package
   TestAccessors;
 use POEx::MUD::Tools::AutoloadAccessors;
}

my $obj = TestAccessors->new(
  testing => 1,
  things  => 'stuff',
  hash => {
    stuff => 'things',
  },
);

cmp_ok($obj->testing, '==', 1, 'Int');
cmp_ok($obj->things, 'eq', 'stuff', 'Str');
cmp_ok($obj->hash->stuff, 'eq', 'things', 'Autoinflation');
ok($obj->has_things, 'Predicate (true)');
ok(!$obj->has_nothing, 'Predicate (false)');
dies_ok(sub { $obj->nonexistant }, 'Nonexistant method dies');

{
  package
    TestWithNew;
  use POEx::MUD::Tools::AutoloadAccessors ();
  sub new {
    my $self = bless { abc => 1 }, shift;
    POEx::MUD::Tools::AutoloadAccessors->import;
    $self
  }
}

my $obj2 = TestWithNew->new;
cmp_ok($obj2->abc, '==', 1, 'new() override ok' );

done_testing;
