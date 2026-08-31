use strict;
use warnings;

my $file = shift @ARGV // q{coverage.txt};
open my $fh, q{<}, $file or die qq{Can't open '$file': $!\n};

my $total;
while ( my $line = <$fh> ) {
    next if $line !~ /^Total\s+/;
    $total = $line;
}
close $fh;

die qq{Unable to find Devel::Cover Total row in '$file'\n} if !defined $total;

my @column = split /\s+/, $total;
shift @column if defined $column[0] && $column[0] eq q{};
shift @column;    # Total

my @name = qw/statement branch condition subroutine/;
for my $index ( 0 .. $#name ) {
    my $value = $column[$index];
    die qq{Coverage report did not contain $name[$index] coverage\n}
      if !defined $value || $value eq q{n/a};
    $value =~ s/%$//;
    die sprintf qq{%s coverage is %s%%; 100%% is required\n}, $name[$index], $value
      if $value + 0 < 100;
}

print qq{100% statement, branch, condition, and subroutine coverage confirmed.\n};
