package WWW::LinkChecker::Internal::App::Command::check;

use strict;
use warnings;
use 5.014;

use WWW::LinkChecker::Internal::App -command;

use List::Util 1.34 qw/ any none /;
use WWW::Mechanize ();

use WWW::LinkChecker::Internal::API::Worker ();

sub description
{
    return "check a site for broken internal links";
}

sub abstract
{
    return shift->description();
}

sub opt_spec
{
    return (
        [ "base=s",                "Base URL", ],
        [ 'before-insert-skip=s@', "before-insert-skip regexes", ],
        [ 'pre-skip=s@',           "pre-skip regexes", ],
        [ 'start=s',               "alternative start URL", ],
        [ 'state-filename=s' => 'filename to keep the state', ],
    );
}

sub execute
{
    my ( $self, $opt, $args ) = @_;

    return WWW::LinkChecker::Internal::API::Worker->new(
        {
            before_insert_skip =>
                [ map { qr/$_/ } @{ $opt->{before_insert_skip} } ],
        }
    )->run($opt);
}

1;
