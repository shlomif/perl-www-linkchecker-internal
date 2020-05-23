package WWW::LinkChecker::Internal::App::Command::check;

use strict;
use warnings;
use 5.014;

use WWW::LinkChecker::Internal::App -command;

use List::Util 1.34 qw/ any none /;
use WWW::Mechanize ();

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
    my $base_url = $opt->{base};
    if ( !defined($base_url) )
    {
        die "--base must be specified";
    }

    my @pre_skip_regexes = map { qr/$_/ } @{ $opt->{pre_skip} };
    my @before_insert_skips_regexes =
        map { qr/$_/ } @{ $opt->{before_insert_skip} };

    my $alternative_start_url = $opt->{start};
    my $state_fn              = $opt->{state_filename};
    my $start_url             = ( $alternative_start_url || $base_url );

    my $state =
        +( $state_fn && ( -e $state_fn ) )
        ? decode_json( path($state_fn)->slurp_utf8 )
        : {
        stack            => [ { url => $start_url, from => undef(), } ],
        encountered_urls => { $start_url => 1, },
        };
STACK:

    while ( my $url_rec = pop( @{ $state->{stack} } ) )
    {
        my $url = $url_rec->{'url'};
        print "Checking SRC URL '$url'\n";

        my $mech = WWW::Mechanize->new();
        eval { $mech->get($url); };

        if ($@)
        {
            push @{ $state->{stack} }, $url_rec;
            if ($state_fn)
            {
                path($state_fn)->spew_utf8( encode_json($state) );
            }
            my $from = ( $url_rec->{from} // "START" );
            die "SRC URL $from points to '$url'.";
        }

        if ( any { $url =~ $_ } @pre_skip_regexes )
        {
            next STACK;
        }

        foreach my $link ( $mech->links() )
        {
            my $dest_url = $link->url_abs() . "";
            $dest_url =~ s{#[^#]+\z}{}ms;
            if (    ( !exists( $state->{encountered_urls}->{$dest_url} ) )
                and $dest_url =~ m{\A\Q$base_url\E}ms
                and ( none { $dest_url =~ $_ } @before_insert_skips_regexes ) )
            {
                $state->{encountered_urls}->{$dest_url} = 1;
                push @{ $state->{stack} }, { url => $dest_url, from => $url, };
            }
        }
    }

    print
"Finished checking the site under the base URL '$base_url'.\nNo broken links were found\n";

    return;
}

1;
