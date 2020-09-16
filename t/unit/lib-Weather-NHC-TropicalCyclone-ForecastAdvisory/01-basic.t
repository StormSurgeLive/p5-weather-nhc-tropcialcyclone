use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp ();
use FindBin qw/$Bin/;

use_ok q{Weather::NHC::TropicalCyclone::ForecastAdvisory};

my @methods = qw/new extract_and_save_atcf save_atcf extract_atcf _parseIotachs/;

can_ok q{Weather::NHC::TropicalCyclone::ForecastAdvisory}, @methods;

my $fh     = File::Temp->new();
my $output = $fh->filename;

is 0, ( stat($output) )[6], q{Output file currently of size 0};

my $input = qq{$Bin/../../data/017.al202020.fst.txt};

ok -e $input, q{Found input file to use for testing.};

dies_ok { my $fst_obj1 = Weather::NHC::TropicalCyclone::ForecastAdvisory->new( input => $input ) } q{'new' constructure dies when not provided with an 'input' parameter};

dies_ok { my $fst_obj2 = Weather::NHC::TropicalCyclone::ForecastAdvisory->new( output => $output ) } q{'new' constructure dies when not provided with an 'output' parameter};

my $fst_obj = Weather::NHC::TropicalCyclone::ForecastAdvisory->new( input => $input, output => $output );

isa_ok $fst_obj, q{Weather::NHC::TropicalCyclone::ForecastAdvisory};

is $input, $fst_obj->input, q{'input' accessor returns exected name used in constructor};

is $output, $fst_obj->output, q{'output' accessor returns exected name used in constructor};

lives_ok { $fst_obj->extract_atcf } q{'extract_atfc' completes with out throwing an exception};

is( q{ARRAY}, ref $fst_obj->as_atcf, q{After 'extract_atcf', 'as_atcf' accessor returns an array deference.'} );

lives_ok { $fst_obj->save_atcf } q{'save_atfc' completes with out throwing an exception};

unlink $output;

lives_ok { $fst_obj->extract_and_save_atcf } q{'extract_and_save_atfc' completes with out throwing an exception};

is( q{ARRAY}, ref $fst_obj->as_atcf, q{After 'extract_atcf', 'as_atcf' accessor returns an array deference.'} );

{
    $/ = undef;
    open my $fh1, q{<}, qq{$Bin/../../data/017.al202020.fst} or die $!;
    open my $fh2, q{<}, $output                              or die $!;

    my $control = <$fh1>;
    my $outfile = <$fh2>;

    is( $control, $outfile, q{Output file looks correct.} );
}

done_testing;

__END__
