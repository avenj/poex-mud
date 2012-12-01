use Test::More; use Test::Exception;
use strict; use warnings FATAL => 'all';

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

diag("Basic autoloaded accessor tests:");
cmp_ok($obj->testing, '==', 1, 'Int');
cmp_ok($obj->things, 'eq', 'stuff', 'Str');
cmp_ok($obj->hash->stuff, 'eq', 'things', 'Autoinflation');
ok($obj->has_things, 'Predicate (true)');
ok(!$obj->has_nothing, 'Predicate (false)');
dies_ok(sub { $obj->nonexistant }, 'Nonexistant method dies');

done_testing;
