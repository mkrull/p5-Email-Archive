package Email::Archive::Storage::MongoDB;
use Moo;
use Carp;
use Email::MIME;
use Email::Abstract;
use MongoDB;
use autodie;
with q/Email::Archive::Storage/;

has host => (
    is => 'rw',
    default => 'localhost',
);

has port => (
    is => 'rw',
    default => 27017,
);

has database => (
    is => 'rw',
);

has collection => (
    is => 'rw',
);

sub store {
  my ($self, $email) = @_;
  $email = Email::Abstract->new($email);
  $self->collection->insert({
    message_id => $email->get_header('Message-ID'),
    from_addr  => $email->get_header('From'),
    to_addr    => $email->get_header('To'),
    date       => $email->get_header('Date'),
    subject    => $email->get_header('Subject'),
    body       => $email->get_body,
  });
}

sub search {
  my ($self, $attribs) = @_;
  my $message = $self->collection->find_one($attribs);

  return Email::MIME->create(
    header => [
      From    => $message->{from_addr},
      To      => $message->{to_addr},
      Subject => $message->{subject},
    ],
    body => $message->{body},
  );
}

sub retrieve {
  my ($self, $message_id) = @_;
  $self->search({ message_id => $message_id });
}

sub storage_connect {
  my ($self, $mongo_con_info) = @_;
  if (defined $mongo_con_info){
    # should look like host:port:database
    my ($host, $port, $database, $collection) = split ':', $mongo_con_info;
    $self->host($host);
    $self->port($port);
    $self->database($database);
    $self->collection($collection);
  }

  my $conn = MongoDB::Connection->new(
    host => $self->host,
    port => $self->port,
  );

  my $datab = $self->database;
  my $collec = $self->collection;

  my $db = $conn->$datab;
  my $coll = $db->$collec;

  # replace name with actual collection object
  $self->collection($coll);

  return 1;
}
