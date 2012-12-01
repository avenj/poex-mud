package POEx::MUD::ReadWrite::YAML;

## The standard reader/writer for rooms, world objects, etc.

use 5.12.1;
use Carp;
use Try::Tiny;
use YAML::Tiny;

use Role::Tiny::With;
with 'POEx::MUD::ReadWrite::Interface';

use namespace::clean;

sub new { bless [], shift }

sub keeps_state { 0 }

sub freeze {
  my (undef, $data) = @_;
  YAML::Tiny::Dump($data)
}

sub freeze_to_file {
  my (undef, $data, $file) = @_;
  confess "Expected a reference and a file path"
    unless defined $data and defined $file;

  YAML::Tiny::DumpFile($file, $data)
}

sub thaw {
  my (undef, $data) = @_;
  YAML::Tiny::Load($data);
}

sub thaw_file {
  my (undef, $path) = @_;
  YAML::Tiny::LoadFile($path)
}


1;
