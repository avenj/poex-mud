use strict; use warnings FATAL => 'all';
use Module::Build;
Module::Build->subclass(
  class => 'POEx::MUD::_Builder',
)->new(
  module_name   => 'POEx::MUD',
  license       => 'perl',
  dist_abstract => 'Pluggable POE-powered MUD server',
  dist_author   => 'Jon Portnoy <avenj@cobaltirc.org>',

  recursive_test_files => 1,
  create_readme      => 1,
  create_makefile_pl => 'small',

  configure_requires => {
    'Module::Build' => '0.40',
  },

  build_requires => {
  },
  
  requires => {
    perl => '5.12.1',

    Carp     => 0,
    Exporter => 0,
    Socket   => 2,

    strictures         => 1,
    'namespace::clean' => '0.23',

    Moo                => 1,
    'MooX::Types::MooseLike'   => 0,
    'MooX::Role::POE::Emitter' => '0.10',

    'Module::Runtime'  => 0,
    'Net::IP::Minimal' => '0.04',
    'Try::Tiny'        => 0,

    POE    => '1.3',
  },

  meta_merge => {
    resources => {
      repository => 'http://github.com/avenj/poex-mud.git',
    },
  },

)->create_build_script;
