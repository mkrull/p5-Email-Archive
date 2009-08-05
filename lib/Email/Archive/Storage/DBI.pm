package Email::Archive::Storage::DBI;
use Moose;
use DBI;
use File::ShareDir 'module_file';
use File::Slurp 'read_file';
use Email::Simple::Creator;
use Email::Abstract;
use SQL::Abstract;
use autodie;
with q/Email::Archive::Storage/;

has dsn => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has sqla => (
  is   => 'ro',
  isa  => 'SQL::Abstract',
  lazy => 1,
  default => sub { SQL::Abstract->new },
  handles => [qw/
    select
    insert
  /],
);

has dbh => (
  is   => 'rw',
  isa  => 'DBI::db',
  handles => [qw/
    prepare
    do
  /],
);

has deployed_schema_version => (
  is  => 'rw',
  isa => 'Int',
  default => 0,
);

my $SCHEMA_VERSION = 0;

sub store {
  my ($self, $email) = @_;
  # passing an E::A to E::A->new is perfectly valid
  $email = Email::Abstract->new($email);
  my $fields = {
    from_addr   => $email->get_header('From'),
    to_addr     => $email->get_header('To'),
    date        => $email->get_header('Date'),
    subject     => $email->get_header('Subject'),
    message_id  => $email->get_header('Message-ID'),
    body        => $email->get_body,
  };
  my ($sql, @bind) = $self->insert('messages', $fields);
  my $sth = $self->prepare($sql);
  $sth->execute(@bind);
}

sub search {
  my ($self, $attribs) = shift;
  my ($sql, @bind) = $self->select('messages', [qw/message_id from_addr to_addr date subject body/], $attribs);
  my $sth = $self->prepare($sql);
  $sth->execute(@bind);
  my ($message) = $sth->fetchrow_hashref;
  return Email::Simple->create(
    header => [
      From    => $message->{from_addr},
      To      => $message->{to_addr},
      Subject => $message->{subject},
    ],
    body => $message->{body},
  );
}

sub retrieve {
  my ($self, $message_id) = shift;
  $self->search({message_id => $message_id});
}

sub _deploy {
  my ($self) = @_;
  my $schema = module_file('Email::Archive::Storage::DBI', 'latest_schema.txt');
  my $sql = read_file($schema);
  $self->do($sql);
}

sub BUILD {
  my ($self) = @_;
  $self->dbh(DBI->connect($self->dsn));
  if(!$self->_deployed) {
    $self->_deploy;
  }
  elsif(!$self->_is_latest_schema) {
    croak sprintf "Schema version %d not supported; we support version " .
                  "$SCHEMA_VERSION. Please upgrade your schema before "  .
                  "continuing.", $self->_deployed_schema_version;
  }
}

sub _deployed {
  my ($self) = @_;
  my $schema_version = eval { $self->selectcol_array('SELECT schema_version FROM metadata') };
  if(defined $schema_version and $schema_version =~ /^\d+$/) {
    $self->deployed_schema_version($schema_version);
    return $schema_version =~ /^\d+$/;
  }
}

1;
