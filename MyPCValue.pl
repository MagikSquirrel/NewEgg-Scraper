#!/usr/bin/perl
use Components;
use Data::Dumper;

#What are the Newegg Numbers for the PC components
my $NEIDs = {
	"HDD" => "N82E16822136514",
	"CPU Fan" => "N82E16835103055",
	"Mobo" => "N82E16813128480",
	"DVD Drive" => "N82E16827106369",
	"CPU" => "N82E16819115070",
	"Monitor" => "N82E16824001431",
	"RAM" => "N82E16820231314",
	"Video Card" => "N82E16814121424",
	"Power Supply" => "N82E16817139011",
	"SDD" => "N82E16820227706",
	"Keyboard" => "N82E16823114004",
	"Mouse" => "N82E16826153057",
	"Mousepad" => "N82E16826999067",
};

#Create an object for each item, get newegg info
my $Components = {};
while (($key, $value) = each(%{$NEIDs})){
	my $part = new Component();
	$part->newEggNum($value);
	$part->tickleNewEgg();
	$Components->{$key} = $part;
}

#Tally the total cost
my $total;
while (($key, $value) = each(%{$Components})){
	my $name = $value->name() || $key;
	my $price = $value->price();
	
	print "$name\t$price\n";
	$total += $price;
}

print "----------\nTOTAL: $total\n";


