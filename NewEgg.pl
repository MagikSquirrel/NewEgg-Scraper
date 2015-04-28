#!/usr/bin/perl
use Components;
use Data::Dumper;

#No argument
if(scalar(@ARGV) == 0){print "Usage: ./NewEgg.pl NewEgg#\n"; exit};

#Create part object, then fetch data
my $part = new Component();
$part->newEggNum($ARGV[0]);

$part->tickleNewEgg();
#$part->ticklePassMark();
#$part->saveDB();
#$part->loadDB();

#Print out stats
#$part->print();

#my $cat = $part->component();
#print "Which is in category ($cat)\n";

#my $pts = $part->score();
#print "Which recieved a PassMark score of ($pts)\n";

#Do raw dump
print Dumper($part);
