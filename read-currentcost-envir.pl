#!/usr/bin/perl -w
# Reads data from a Current Cost EnviR device via serial port.

use strict;
use warnings;
use Device::SerialPort qw( :PARAM :STAT 0.07 );
use LWP::UserAgent;

my $key = "ADD WRITE API KEY HERE";
my $host = "R-Pi EmonBase IP address";
my $PORT = "/dev/ttyUSB0"; # Serial device 
my $meas = 0;
my $sumW = 0;
my $sumT = 0;
my $watts;
my $temp;

my $ob = Device::SerialPort->new($PORT)  || die "Can't open $PORT: $!\n";
$ob->baudrate(57600);
$ob->write_settings;

open(SERIAL, "+>$PORT");
while (my $line = <SERIAL>) {
	if ($line =~ m!<tmpr>\s*(-*[\d.]+)</tmpr>.*<ch1><watts>0*(\d+)</watts></ch1>!) {
		my $temp = $1;
		my $watts = $2;
		print "SUCCESS $meas: ... $watts, $temp\n";
		$meas++;
		$sumW += $watts;
		$sumT += $temp;
	}
	if ($meas == 2) { # Frequency for sending data
	   $watts = $sumW/2;
	   $temp = $sumT/2;
		print "AVERAGE: ... $watts, $temp\n";
		my $emon_ua = LWP::UserAgent->new;
		my $emon_url = "http://$host/emoncms/input/post.json?apikey=$key\&json={power:$watts,temp:$temp}";
	my $emon_response = $emon_ua->get($emon_url);
	$meas = $sumW = $sumT = 0;
	}
}

