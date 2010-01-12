#!/usr/bin/perl
use strict; use warnings;

# Load our modules
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Data::Dumper;

# Set some variables we need to control the fetcher
my $dota_mainpage = 'http://www.getdota.com';
my $dota_getmap = 'http://www.getdota.com/app/getmap/';

# get the misc data we need to request the map!
my $ua = LWP::UserAgent->new;
#my $response = $ua->get( $dota_mainpage );
#if ( ! $response->is_success ) {
#	die "Failed to GET: " . $response->status_line;
#}

# Get some misc data from the content
my $tree = HTML::TreeBuilder::XPath->new_from_file( 'getdota.htm' );
#my $tree = HTML::TreeBuilder::XPath->new_from_content( $response->content );

# TODO this works fine, but I worry for the day it "finds" the old map...
# <div class="header">Latest Map: <span class="version">6.65</span></div>
my @nodes = $tree->findnodes( '/html/body//div[@class="header"]//span[@class="version"]' );
#print Dumper( \@nodes );
my $dota_ver = ( $nodes[0]->content_list )[0];
print "Dota Version: $dota_ver\n";

exit;


@nodes = $tree->findnodes( '/html/body//table[@class="tbl-downloads"]//input[@id="input_map_id2"]' );
my $map_id = $nodes[0]->attr( 'value' );

@nodes = $tree->findnodes( '/html/body//table[@class="tbl-downloads"]//input[@id="input_file_name2"]' );
my $map_name = $nodes[0]->attr( 'value' );

# get the map location!
my %dota_data = (
	'mirror_id'	=> 0,		# selects the random mirror
	'mirror_nr'	=> 2,		# selects the latest map
	'language'	=> 'en',	# <input type="hidden" name="language" value="en" id="input_language2"/>
	'language_id'	=> 2,		# <input type="hidden" name="language_id" value="2" id="input_language_id2"/>
	'map_id'	=> $map_id,
	'as_zip'	=> 0,		# <input type="checkbox" name="as_zip2" value="1" id="as_zip2"/> # why is it 1 in the HTML when 0 is what we want?
	'file_name'	=> $map_name,
);

print Dumper( \%dota_data );

my $response = $ua->post( $dota_getmap, \%dota_data );
if ( $response->is_success ) {
	print $response->content, "\n";
} else {
	die "Failed to POST: " . $response->status_line;
}

