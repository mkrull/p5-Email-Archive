package Email::Archive::Storage;
use Moose::Role;

requires qw/store retrieve search storage_connect/;
1;
