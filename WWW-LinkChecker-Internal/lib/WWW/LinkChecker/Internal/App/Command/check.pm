package WWW::LinkChecker::Internal::App::Command::check;

use strict;
use warnings;
use 5.014;

use WWW::LinkChecker::Internal::App -command;

use WWW::LinkChecker::Internal::API::Worker ();

use Term::ANSIColor qw( colored );

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
        [ 'only-check-site-flow!', 'only-check-site-flow!', ],
        [ 'start=s',               "alternative start URL", ],
        [ 'state-filename=s' => 'filename to keep the state', ],
    );
}

sub _regexify
{
    my ( $self, $arr ) = @_;

    return [ map { qr/$_/ } @{$arr} ];
}

sub execute
{
    my ( $self, $opt, $args ) = @_;
    my $base_url = ( $opt->{base} // ( die "--base must be specified" ) );
    my $ret      = WWW::LinkChecker::Internal::API::Worker->new(
        {
            base_url           => $base_url,
            before_insert_skip =>
                $self->_regexify( $opt->{before_insert_skip} ),
            only_check_site_flow => $opt->{only_check_site_flow},
            pre_skip             => $self->_regexify( $opt->{pre_skip} ),
            start_url            => $opt->{start},
            state_filename       => $opt->{state_filename},
        }
    )->run(
        {
            check_url_inform_cb => sub {
                my ($args) = @_;
                my $url = $args->{url};
                print "Checking SRC URL '$url'\n";
                return;
            },

        }
    );

    if ( $ret->{success} )
    {
        print "Finished checking the site under the base URL '$base_url'.\n";
        say colored( "No broken links were found", "green on_black" );

    }
    return;
}

1;
