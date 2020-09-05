use strict;
use warnings;
use FindBin qw/$Bin/;
use JSON::XS   ();
use File::Temp ();

use Test::More;
use Test::Exception;

use_ok q{Weather::NHC::TropicalCyclone};

my $obj = Weather::NHC::TropicalCyclone->new;
isa_ok $obj, q{Weather::NHC::TropicalCyclone}, q{Can create instance of Weather::NHC::TropicalCyclone};

can_ok( $obj, (qw/new fetch active_storms fetch_atlantic_rss fetch_east_pacific_rss fetch_central_pacific_rss/) );

{
    ok $Weather::NHC::TropicalCyclone::DEFAULT_ATLANTIC_RSS,        q{Found default Atlantic RSS};
    ok $Weather::NHC::TropicalCyclone::DEFAULT_EAST_PACIFIC_RSS,    q{Found default Eastern Pacific RSS};
    ok $Weather::NHC::TropicalCyclone::DEFAULT_CENTRAL_PACIFIC_RSS, q{Found default Central Pacific RSS};

    local $Weather::NHC::TropicalCyclone::DEFAULT_ATLANTIC_RSS        = q{obviously bad url};
    local $Weather::NHC::TropicalCyclone::DEFAULT_EAST_PACIFIC_RSS    = q{foo bar};
    local $Weather::NHC::TropicalCyclone::DEFAULT_CENTRAL_PACIFIC_RSS = q{herp derp};

    dies_ok sub { $obj->fetch_atlantic_rss },        q{ rss fails on bad atlantic request };
    dies_ok sub { $obj->fetch_east_pacific_rss },    q{ rss fails on bad east pacific request };
    dies_ok sub { $obj->fetch_central_pacific_rss }, q{ rss fails on bad central pacific request };
}

my $at_rss = q{};
ok $at_rss = $obj->fetch_atlantic_rss, q{make atlantic rss call};
like $at_rss, qr/<rss/, q{appears to be RSS};

{
    my $fh        = File::Temp->new();
    my $atl_fname = $fh->filename;
    ok $at_rss = $obj->fetch_atlantic_rss($atl_fname), q{make atlantic rss call};
    like $at_rss, qr/<rss/, q{appears to be RSS};
    ok -e $atl_fname, q{RSS file detected};
    local $/;
    my $atl_fname_rss = <$fh>;
    like $atl_fname_rss, qr/<rss/, q{saved file appears to be RSS};
    close $fh;
}

my $ep_rss = q{};
ok $ep_rss = $obj->fetch_east_pacific_rss, q{make east pacific rss call};
like $ep_rss, qr/<rss/, q{appears to be RSS};

{
    my $fh         = File::Temp->new();
    my $epac_fname = $fh->filename;
    ok $ep_rss = $obj->fetch_east_pacific_rss($epac_fname), q{make east rss call};
    like $ep_rss, qr/<rss/, q{appears to be RSS};
    ok -e $epac_fname, q{RSS file detected};
    local $/;
    my $epac_fname_rss = <$fh>;
    like $epac_fname_rss, qr/<rss/, q{saved file appears to be RSS};
    close $fh;
}

my $cp_rss = q{};
ok $cp_rss = $obj->fetch_central_pacific_rss, q{make central pacific rss call};
like $cp_rss, qr/<rss/, q{appears to be RSS};

{
    my $fh         = File::Temp->new();
    my $cpac_fname = $fh->filename;
    ok $cp_rss = $obj->fetch_central_pacific_rss($cpac_fname), q{make central rss call};
    like $cp_rss, qr/<rss/, q{appears to be RSS};
    ok -e $cpac_fname, q{RSS file detected};
    local $/;
    my $cpac_fname_rss = <$fh>;
    like $cpac_fname_rss, qr/<rss/, q{saved file appears to be RSS};
    close $fh;
}

open my $dh, q{<}, qq{$Bin/../../data/CurrentStorms.json} or die $!;
local $/;
my $json     = <$dh>;
my $json_ref = JSON::XS::decode_json $json;
$obj->{_obj} = $json_ref;
ok exists $json_ref->{activeStorms}, q{data for test set up ok};
ok ref $obj->active_storms eq q{ARRAY}, q{active_storms is an array ref};

# simulating HTTP::Tiny->get...
{
    no warnings qw/redefine once/;
    local *HTTP::Tiny::get = sub {
        return { content => $json, status => 200 };
    };
    my $obj2 = Weather::NHC::TropicalCyclone->new;
    isa_ok $obj2, q{Weather::NHC::TropicalCyclone}, q{Can create instance of Weather::NHC::TropicalCyclone};
    ok $obj2->fetch, q{testing 'fetch' method};
    is( 2, scalar @{ $obj2->{_obj}->{activeStorms} }, q{active_storms count is as expected} );
    for my $s ( @{ $obj2->active_storms } ) {
        isa_ok $s, q{Weather::NHC::TropicalCyclone::Storm};
    }

    # test alarm in fetch
    local *HTTP::Tiny::get = sub {
        sleep 2;
    };

    dies_ok( sub { $obj2->fetch(1) }, q{testing 'fetch' method timeout} );
}

done_testing;

__END__
