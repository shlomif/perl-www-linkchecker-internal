package WWW::LinkChecker::Internal::API::Worker;

use strict;
use warnings;
use 5.014;

use Moo;

use JSON::MaybeXS   qw( decode_json encode_json );
use List::Util 1.34 qw/ any none /;

use Path::Tiny qw/ path /;

use WWW::Mechanize ();

has 'base_url'             => ( is => 'ro', required => 1 );
has 'before_insert_skip'   => ( is => 'ro', required => 1 );
has 'pre_skip'             => ( is => 'ro', required => 1 );
has 'only_check_site_flow' => ( is => 'ro', );
has 'start_url'            => ( is => 'ro', );
has 'state_filename'       => ( is => 'ro', );

sub run
{
    my ( $self, $args ) = @_;

    my $check_url_inform_cb =
        ( $args->{check_url_inform_cb} // sub { return; } );
    my $base_url = $self->base_url;
    if ( !defined($base_url) )
    {
        die "--base must be specified";
    }
    my @before_insert_skips_regexes = @{ $self->before_insert_skip() };

    my @pre_skip_regexes      = @{ $self->pre_skip() };
    my $alternative_start_url = $self->start_url();
    my $only_check_site_flow  = $self->only_check_site_flow();
    my $state_fn              = $self->state_filename();
    my $start_url             = ( $alternative_start_url || $base_url );

    my $state =
        +( $state_fn && ( -e $state_fn ) )
        ? decode_json( path($state_fn)->slurp_utf8 )
        : {
        stack            => [ $start_url, ],
        encountered_urls => { $start_url => undef(), },
        };
    my $stack            = $state->{stack};
    my $encountered_urls = $state->{encountered_urls};
    my $prev;
    my $dest_url;
    my $url;
STACK:

    while ( my $url_rec = pop( @{$stack} ) )
    {
        $dest_url = undef;
        $url      = $url_rec;
        $check_url_inform_cb->( { url => $url, } );

        my $mech = WWW::Mechanize->new();
        eval { $mech->get($url); };

        if ($@)
        {
            push @{$stack}, $url_rec;
            if ($state_fn)
            {
                path($state_fn)->spew_utf8( encode_json($state) );
            }
            my $from = ( $encountered_urls->{$dest_url} // "START" );
            die "SRC URL $from points to '$url'.";
        }

        if ( any { $url =~ $_ } @pre_skip_regexes )
        {
            next STACK;
        }
        my $process = sub {
            my ($link) = @_;
            $dest_url = $link->url_abs() . "";
            $dest_url =~ s{#[^#]+\z}{}ms;
            if (    ( !exists( $encountered_urls->{$dest_url} ) )
                and $dest_url =~ m{\A\Q$base_url\E}ms
                and ( none { $dest_url =~ $_ } @before_insert_skips_regexes ) )
            {
                $encountered_urls->{$dest_url} = $url;
                push @{$stack}, $dest_url;
            }
        };
        foreach my $link ( $mech->links() )
        {
            if ($only_check_site_flow)
            {
                if ( $link->tag() eq 'link' )
                {
                    my $rel = $link->attrs()->{'rel'};
                    if ( $rel eq 'prev' )
                    {
                        if ( defined $prev )
                        {
                            if ( $link->url_abs ne $prev )
                            {
                                die "prev";
                            }
                            else
                            {
                                say "prev = $prev ;";
                            }
                        }
                    }
                    elsif ( $rel eq 'next' )
                    {
                        $process->($link);
                    }
                }
            }
            else
            {
                $process->($link);
            }
        }
    }
    continue
    {
        if ($only_check_site_flow)
        {
            if ( !defined($dest_url) )
            {
                die "no next at SRC = $url";
            }
            $prev = $url;
        }
    }

    return +{ success => 1, };
}

1;

=encoding utf8

=head1 NAME

WWW::LinkChecker::Internal::API::Worker - API object

=head1 SYNOPSIS

=head1 DESCRIPTION

(This module was added in version 0.10.0 .)

=head1 METHODS

=head2 base_url()

The site's base URL.

=head2 before_insert_skip()

Before-insert-skip regexes.

=head2 only_check_site_flow()

Only check site-flow links.

=head2 pre_skip()

Pre-skip regexes.

=head2 run()

Runs the check.

=head2 start_url()

Alternative start URL; defaults to base_url().

=head2 state_filename()

Filename to keep the persistence state (optional).

=cut

