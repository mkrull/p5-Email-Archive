package Email::Archive;
use Moose;
use Module::Load;

has storage => (
  is    => 'rw',
  does  => 'Email::Archive::Storage',
  handles     => [qw/
    store
    retrieve
    search
  /],
  lazy_build  => 1,
);

has dsn => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has storage_class => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
  default  => 'Email::Archive::Storage::DBI',
);

sub _build_storage {
  my ($self) = @_;
  load $self->storage_class;
  my $storage = $self->storage_class->new(dsn => $self->dsn);
}

1;
