#!/usr/bin/perl
use strict;
use warnings;
use Email::MIME;

use Test::More;

use Email::Archive;
use Email::Archive::Storage::DBIC;

my $email = Email::MIME->create(
    header => [
      From    => 'foo@example.com',
      To      => 'drain@example.com',
      Subject => 'Message in a bottle',
      'Message-ID' => 'helloworld',
    ],
    body => 'hello there!'
);

my $e = Email::Archive->new();
$e->connect('dbi:SQLite:dbname=t/test.db');
$e->store($email);

my $found = $e->retrieve('helloworld');
cmp_ok($found->header('subject'), 'eq', "Message in a bottle",
  "can find stored message by ID");

my $e_dbic = Email::Archive->new(
    storage => Email::Archive::Storage::DBIC->new,
);
$e_dbic->connect('dbi:SQLite:dbname=t/test_dbic.db');
$e_dbic->store($email);

$found = $e_dbic->retrieve('helloworld');
cmp_ok($found->header('subject'), 'eq', "Message in a bottle",
  "can find stored message by ID");


done_testing;
unlink 't/test.db';
unlink 't/dbic_test.db';
