#!/usr/bin/env perl

package local::bin::nhcwatchd;

use strict;
use warnings;

use JSON::XS   ();
use HTTP::Tiny ();
use HTTP::Status qw/:constants/;
use Getopt::Long                         ();
use Weather::NHC::TropicalCyclone::Storm ();
use Data::Dumper                         ();

our $DEFAULT_URL = q{https://www.nhc.noaa.gov/CurrentStorms.json};
our $LATEST_JSON = q{CurrentStorms.json.latest};

use constant {
    EXIT_SUCCESS => 0,
    EXIT_ERROR   => 1,
};

if ( not caller ) {
    my %opts;
    my $ret = Getopt::Long::GetOptions( \%opts, q{file=s}, q{interval=i}, q{once}, q{save}, q{url=s} );

    $opts{url} //= $DEFAULT_URL;

    exit __PACKAGE__->run( \%opts );
}

sub run {
    my ( $self, $opts_ref ) = @_;

    my $http = HTTP::Tiny->new();

    # get content via $DEFAULT_URL unless --file option is passed
    my $content;
    if ( not $opts_ref->{file} ) {
        local $@;
        my $response = eval { $http->get( $opts_ref->{url} ) };
        if ( $@ or not $response or $response->{status} ne http_ok ) {
            print qq{request error\n};
            return exit_error;
        }
        $content = $response->{content};
    }
    else {
        # $opts_ref->{file} is assumed to exist, but this will die in error if it doesn't,
        # so there is no need to check
        open my $fh, q{<}, $opts_ref->{file} or die qq{Error opening $opts_ref->{file}: $!\n};
        local $/;
        $content = <$fh>;
    }

    local $@;
    my $ref = eval { JSON::XS::decode_json $content };

    if ( $@ or not $ref ) {
        print qq{JSON decode error\n};
        return EXIT_ERROR;
    }

    # write JSON file
    if ( $opts_ref->{save} ) {

        # move the latest file saved locally to .bak, if detected
        if ( -e $LATEST_JSON ) {
            rename qq{$LATEST_JSON}, qq{$LATEST_JSON.bak} or die qq{Error saving backup JSON file: $!\n};
        }
        open my $fh, q{>}, $LATEST_JSON or die qq{Can't open $LATEST_JSON for writing: $!\n};
        print $fh $content;
        close $fh;
    }

    if ( not @{ $ref->{activeStorms} } ) {
        print qq{No active storms detected.\n};
        return EXIT_SUCCESS;
    }

    my $active_storm_count = @{ $ref->{activeStorms} };
    print qq{Storms active: $active_storm_count\n};

    for my $storm ( @{ $ref->{activeStorms} } ) {
        my $s = Weather::NHC::TropicalCyclone::Storm->new($storm);
        print $s->basin . qq{\n};
        print $s->forecastAdvisory->{url} . qq{\n};
        my $id = $s->id; # e.g., al132020

        my ($text, $adv, $file) = $s->fetch_forecastAdvisory(qq{$id.fst});
        print qq{wrote $file for Advisory $adv\n} if -e $file;
    }

    return EXIT_SUCCESS;
}

1;

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION
