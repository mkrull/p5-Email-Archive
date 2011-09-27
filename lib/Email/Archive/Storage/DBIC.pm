package Email::Archive::Storage::DBIC;
use Moo;
use Carp;
use Email::MIME;
use Email::Abstract;
use Email::Archive::Storage::DBIC::Schema;
use autodie;
use Try::Tiny;
with q/Email::Archive::Storage/;

has schema => (
  is => 'rw',
  isa => sub {
    ref $_[0] eq 'Email::Archive::Storage::DBIC::Schema' or die "schema must be a Email::Archive::Storage::DBIC schema",
  },
);

sub store {
  my ($self, $email) = @_;
  $email = Email::Abstract->new($email);
  $self->schema->resultset('Messages')->update_or_create({
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
  my $message = $self->schema
                  ->resultset('Messages')
                  ->find($attribs);
  return Email::MIME->create(
    header => [
      From    => $message->from_addr,
      To      => $message->to_addr,
      Subject => $message->subject,
    ],
    body => $message->body,
  );
}

sub retrieve {
  my ($self, $message_id) = @_;
  $self->search({ message_id => $message_id });
}

sub _deploy {
  my ($self) = @_;
  $self->schema->deploy;
}

sub _deployed {
  my ($self) = @_;
  my $deployed = 1;
  try {
      # naive check if table metadata exists
      $self->schema->resultset('Metadata')->all;
  }
  catch {
      $deployed = 0;
  };

  return $deployed;
}

sub storage_connect {
  my ($self, $dsn) = @_;
  $self->schema(Email::Archive::Storage::DBIC::Schema->connect($dsn));
  my $deployed = $self->_deployed;
  $self->_deploy unless $deployed;
}

1;

