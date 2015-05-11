#!/bin/env perl 

use lib '/home/msziraki/src/vfi-um-1.4.0.dev/VFI-UM/files/lib';
use Ascertain::UM::Readers::AMA;

use strict;
use diagnostics;

my $amaFile = shift;

if (not -f $amaFile)
{
	print "File not found : $amaFile\n";
	exit 1;
}

my $oAMA = Ascertain::UM::Readers::AMA->new({input_file => $amaFile});

$oAMA->getNextRecord();



