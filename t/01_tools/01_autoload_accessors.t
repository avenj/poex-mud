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
cmp_ok($obj->testing, '==', 1);
cmp_ok($obj->things, 'eq', 'stuff');
cmp_ok($obj->hash->stuff, 'eq', 'things');
dies_ok(sub { $obj->nonexistant });

done_testing;
