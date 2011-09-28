#!/usr/bin/perl
use strict;
use warnings;
use Email::MIME;

use Test::More;

use Email::Archive;
use Email::Archive::Storage::MongoDB;

my $email = Email::MIME->create(
  header => [
    From    => 'foo@example.com',
    To      => 'drain@example.com',
    Subject => 'Message in a bottle',
    'Message-ID' => 'helloworld',
  ],
  body => 'hello there!'
);

my $storage = Email::Archive::Storage::MongoDB->new(
  host       => 'localhost',
  port       => 27017,
  database   => 'EmailArchiveTestMongoDB',
  collection => 'emails',
);

my $e = Email::Archive->new(
  storage => $storage,
);

$e->connect;
$e->store($email);

my $found = $e->retrieve('helloworld');

$found = $e->retrieve('helloworld');
cmp_ok($found->header('subject'), 'eq', "Message in a bottle",
  "can find stored message by ID");


done_testing;

my $conn = MongoDB::Connection->new(
    host => 'localhost',
    port => 27017
);

$conn->EmailArchiveTestMongoDB->drop;

