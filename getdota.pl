#!/usr/bin/perl
use strict; use warnings;

# Load our modules
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Data::Dumper;

# Set some variables we need to control the fetcher
my $dota_mainpage = 'http://www.getdota.com/map_archive/map/last/lang/en';
my $dota_getmap = 'http://www.getdota.com/app/getmap/';

# get the misc data we need to request the map!
my $ua = LWP::UserAgent->new;
my $response = $ua->get( $dota_mainpage );
if ( ! $response->is_success ) {
	die "Failed to GET: " . $response->status_line;
}

# Get some misc data from the content
#my $tree = HTML::TreeBuilder::XPath->new_from_file( 'getdota.htm' );
my $tree = HTML::TreeBuilder::XPath->new_from_content( $response->content );

# TODO this works fine, but I worry for the day it "finds" the old map...
# <div class="header">Latest Map: <span class="version">6.65</span></div>
my @nodes = $tree->findnodes( '/html/body//div[@class="header"]//span[@class="version"]' );
#print Dumper( \@nodes );
my $dota_ver = ( $nodes[0]->content_list )[0];
print "Dota Version: $dota_ver\n";

#exit;

# <input type="hidden" name="map_id" value="249" id="input_map_id1"/>
@nodes = $tree->findnodes( '/html/body//table[@class="tbl-downloads"]//input[@id="input_map_id1"]' );
my $map_id = $nodes[0]->attr( 'value' );

# <input type="hidden" name="file_name" value="DotA Allstars v6.66b.w3x" id="input_file_name1"/>
@nodes = $tree->findnodes( '/html/body//table[@class="tbl-downloads"]//input[@id="input_file_name1"]' );
my $map_name = $nodes[0]->attr( 'value' );

# get the map location!
my %dota_data = (
	'mirror_id'	=> 0,		# <input type="hidden" name="mirror_id" value="0" id="input_mirror1"/>
	'mirror_nr'	=> 2,		# selects the latest map
	'language'	=> 'en',	# <input type="hidden" name="language" value="en" id="input_language1"/>
	'language_id'	=> 2,		# <input type="hidden" name="language_id" value="2" id="input_language_id1"/>
	'map_id'	=> $map_id,
	'as_zip'	=> 0,		# <input type="checkbox" name="as_zip1" value="1" id="as_zip1"/> # why is it 1 in the HTML when 0 is what we want?
	'file_name'	=> $map_name,
);

print Dumper( \%dota_data );

$response = $ua->post( $dota_getmap, \%dota_data );
if ( $response->is_success ) {
	print $response->content, "\n";
} else {
	die "Failed to POST: " . $response->status_line;
}







# After all this is done, send to GHostOne to load dota!
# ghost@wc3:~$ echo -n "load dota" | nc -u -v -v 127.0.0.1 6969
#
#[Mon Feb  1 16:03:05 2010] [UDPCMDSOCK] Relaying cmd [!load dota] to server [uswest.battle.net]
#[Mon Feb  1 16:03:05 2010] [WSPR: USWest] [the_ap0calypse] !load dota
#[Mon Feb  1 16:03:05 2010] [BNET: USWest] admin [the_ap0calypse] sent command [!load dota]
#[Mon Feb  1 16:03:05 2010] [QUE: USWest] /w the_ap0calypse Loading config file [mapcfgs/dota.cfg].
#[Mon Feb  1 16:03:05 2010] [CONFIG] loading file [mapcfgs/dota.cfg]
#[Mon Feb  1 16:03:05 2010] [MAP] loading MPQ file [maps/DotA Allstars v6.66b.w3x]
#[Mon Feb  1 16:03:05 2010] [MAP] calculated map_size = 176 69 103 0
#[Mon Feb  1 16:03:05 2010] [MAP] calculated map_info = 193 148 215 8
#[Mon Feb  1 16:03:05 2010] [MAP] calculated map_crc = 155 89 252 206
#[Mon Feb  1 16:03:05 2010] [MAP] calculated map_sha1 = 157 115 111 121 18 48 195 98 249 148 244 211 41 156 154 240 196 166 181 216
#[Mon Feb  1 16:03:05 2010] [MAP] calculated map_width = 118 0
#[Mon Feb  1 16:03:05 2010] [MAP] calculated map_height = 120 0
#[Mon Feb  1 16:03:05 2010] [MAP] calculated map_numplayers = 10
#[Mon Feb  1 16:03:05 2010] [MAP] calculated map_numteams = 2
#[Mon Feb  1 16:03:05 2010] [MAP] found 10 slots
#[Mon Feb  1 16:03:05 2010] [ERROR: USWest] That user is not logged on.

# echo -n "say DotA 6.66b Loaded, yay" | nc -u -v -v 127.0.0.1 6969
#
#[Mon Feb  1 16:06:11 2010] [UDPCMDSOCK] Relaying cmd [!say DotA 6.66b Loaded, yay] to server [uswest.battle.net]
#[Mon Feb  1 16:06:11 2010] [WSPR: USWest] [the_ap0calypse] !say DotA 6.66b Loaded, yay
#[Mon Feb  1 16:06:11 2010] [BNET: USWest] admin [the_ap0calypse] sent command [!say DotA 6.66b Loaded, yay]
#[Mon Feb  1 16:06:11 2010] [QUE: USWest] DotA 6.66b Loaded, yay


#      Recipe 17.5 of the Perl Cookbook is handy:

# use IO::Socket;
# use strict;
# my $sock = IO::Socket::INET->new( Proto => 'udp', PeerPort => 5000, PeerAddr => 'hostname', ) or die "Could not create socket: $!\n";
# $sock->send('a file to have your advice') or die "Send error: $!\n";
