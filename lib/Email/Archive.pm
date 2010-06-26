package Email::Archive;
use Moose;
use Email::Archive::Storage::DBI;

has storage => (
  is    => 'rw',
  does  => 'Email::Archive::Storage',
  handles     => {
    store    => 'store',
    retrieve => 'retrieve',
    connect  => 'storage_connect',
  },
  lazy  => 1,
  default => sub { Email::Archive::Storage::DBI->new }
);

1;
