#!/usr/bin/perl
use strict; use warnings;

# Load our modules
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Data::Dumper;
use IO::Socket;
use File::Spec;

# ghost@wc3:~$ crontab -l
# # m h  dom mon dow   command
# 0 * * * * /home/ghost/dota_autoupdate.pl

# Set some config variables
my $dota_mainpage = 'http://www.getdota.com/map_archive/map/last/lang/en';
my $dota_getmap = 'http://www.getdota.com/app/getmap/';
my $ghost_dir = '/home/ghost/GHostOne';
my $ghost_host = 'localhost';
my $ghost_port = 6969;
my $ghost_mapcfg = 'dota.cfg';
my $debug = 1;

# Set some global variables
my $ua = LWP::UserAgent->new;

# Go off and do it's stuff!
main();

# all done!
exit;

sub main {
	# okay, first of all we need to get the current version
	my $dota_current = get_currentversion();

	if ( $debug ) {
		print "Current DotA file: $dota_current\n";
	}

	# Okay, check the website!
	my $dota_data = get_webdata();

	if ( $debug ) {
		print "Website DotA file: $dota_data->{'file_name'}\n";
	}

	# Do we need to update?
	if ( $dota_current ne $dota_data->{'file_name'} ) {
		update_dota( $dota_data );
	}

	return;
}

sub get_currentversion {
	# Look in the GHost folder for the dota stuff
	my $file = File::Spec->catfile( $ghost_dir, 'mapcfgs', $ghost_mapcfg );
	if ( -e $file ) {
		open( my $fh, '<', $file ) or die "Unable to open $file: $!";
		my @contents = <$fh>;
		close( $fh ) or die "Unable to close $file: $!";
		
		# parse the ghost dota.cfg file for dota filename
		return parse_ghostcfg( \@contents );
	} else {
		die "Could not find $file on the system";
	}
}

sub parse_ghostcfg {
	my $contents = shift;

#	ghost@wc3:~/GHostOne/mapcfgs$ cat dota.cfg 
#	map_path = Maps\Download\DotA Allstars v6.66b.w3x
#	map_type = dota
#	map_matchmakingcategory = dota_elo
#	map_localpath = DotA Allstars v6.66b.w3x
#	map_defaulthcl =
#	map_loadingame = 1

	# I should use a proper INI-style loader, but blah!
	foreach my $l ( @$contents ) {
		if ( $l =~ /^map_localpath\s+\=\s+(.+)$/ ) {
			return $1;
		}
	}

	# Couldn't find it!
	die "Unable to find 'map_localpath' in $ghost_mapcfg file!";
}

sub get_webdata {
	# Get the website!
	my $response = $ua->get( $dota_mainpage );
	if ( ! $response->is_success ) {
		die "Failed to GET: " . $response->status_line;
	}

	# Get some misc data from the content
	my( $map_id, $map_name );
	my $tree = HTML::TreeBuilder::XPath->new_from_content( $response->content );

	# <input type="hidden" name="map_id" value="249" id="input_map_id1"/>
	my @nodes = $tree->findnodes( '/html/body//table[@class="tbl-downloads"]//input[@id="input_map_id1"]' );
	if ( defined $nodes[0] ) {
		$map_id = $nodes[0]->attr( 'value' );
	} else {
		die "Unable to get map_id";
	}

	# <input type="hidden" name="file_name" value="DotA Allstars v6.66b.w3x" id="input_file_name1"/>
	@nodes = $tree->findnodes( '/html/body//table[@class="tbl-downloads"]//input[@id="input_file_name1"]' );
	if ( defined $nodes[0] ) {
		$map_name = $nodes[0]->attr( 'value' );
	} else {
		die "Unable to get file_name";
	}

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

	# Return the data!
	return \%dota_data;
}

sub update_dota {
	my $data = shift;

	if ( $debug ) {
		print "Executing DotA update!\n";
	}

	# mirror it!
	mirror_dota( $data );

	# Okay, we need to update the dota.cfg file
	update_dotacfg( $data->{'file_name'} );

	# Tell GHostOne to update the cfg + send announcement
	update_ghost( $data->{'file_name'} );

	return;
}

sub update_dotacfg {
	my $data = shift;

	if ( $debug ) {
		print "Updating GHostOne $ghost_mapcfg file!\n";
	}

	# Construct the data
	my $contents = <<"END";
map_path = Maps\\Download\\$data
map_type = dota
map_matchmakingcategory = dota_elo
map_localpath = $data
map_defaulthcl =
map_loadingame = 1
END

	if ( $debug ) {
		print "New GHostOne $ghost_mapcfg contents: \n$contents\n";
	}

	# Okay, overwrite the dotacfg
	my $file = File::Spec->catfile( $ghost_dir, 'mapcfgs', $ghost_mapcfg );
	open( my $fh, '>', $file ) or die "Unable to open $file: $!";
	print $fh $contents;
	close( $fh ) or die "Unable to close $file: $!";

	return;
}

sub update_ghost {
	my $data = shift;

	if ( $debug ) {
		print "Telling GHostOne to reload $ghost_mapcfg!\n";
	}

	my $sock = IO::Socket::INET->new( Proto => 'udp', PeerPort => $ghost_port, PeerAddr => $ghost_host ) or die "Could not create socket: $!\n";
	$sock->send( "load $ghost_mapcfg" ) or die "Send error: $!\n";

	if ( $debug ) {
		print "Telling GHostOne to send the announcement!\n";
	}

	$sock->send( "say New version of DotA loaded, time to own some n00bs! ( $data )" ) or die "Send error: $!";

	return;
}

sub mirror_dota {
	my $data = shift;

	# Send the request to the website for the mirror link
	my $response = $ua->post( $dota_getmap, $data );
	if ( ! $response->is_success ) {
		die "Failed to POST: " . $response->status_line;
	}

	if ( $debug ) {
		print "Mirroring the latest DotA map from ( " . $response->content . " )!\n";
	}

	# Okay, mirror the file!
	my $localpath = File::Spec->catfile( $ghost_dir, 'maps', $data->{'file_name'} );
	my $response2 = $ua->mirror( $response->content, $localpath );
	if ( ! $response2->is_success ) {
		die "Failed to mirror: " . $response2->status_line;
	}

	return;
}
