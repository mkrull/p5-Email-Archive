package Email::Archive::Storage;
use Moose::Role;

requires qw/store retrieve search/;
1;
