package POEx::MUD::ReadWrite::YAML;

## The standard reader/writer for rooms, world objects, etc.

use 5.12.1;
use Moo;

extends 'POEx::MUD::ReadWrite';

use Try::Tiny;
use YAML::Tiny;

use namespace::clean;


sub freeze {
  my ($self, $data) = @_;
  YAML::Tiny::Dump($data)
}

sub freeze_to_file {
  my ($self, $data, $file) = @_;
  confess "Expected a reference and a file path"
    unless defined $data and defined $file;

  YAML::Tiny::DumpFile($file, $data)
}

sub thaw {
  my ($self, $data) = @_;
  YAML::Tiny::Load($data);
}

sub thaw_file {
  my ($self, $path) = @_;
  YAML::Tiny::LoadFile($path)
}


1;
