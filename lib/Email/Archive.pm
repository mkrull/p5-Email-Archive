package Email::Archive;
use Moo;
use Email::Archive::Storage::DBI;

our $VERSION = '0.02';

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


__END__

=head1 NAME

Email::Archive - write emails to a database, fetch them

=head1 WARNING!

I only uploaded this to get it out there and kick myself into making it more
useful. As you can see it's not documented or tested yet. I put this together
mostly in one evening in a coffeeshop. It shows in some ways. caveat programmer.

=head1 LICENSE

This library may be used under the same terms as Perl itself.

=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2010, 2011 Chris Nehren C<apeiron@cpan.org>.
