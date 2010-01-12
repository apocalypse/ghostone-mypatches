#!/usr/bin/env perl
package GHost::IRC;
use strict;
use warnings;

use POE;
use base 'POE::Session::AttributeBased';
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::AutoJoin;
use POE::Component::IRC::Plugin::FollowTail;

my $ghostlog = '/home/ghost/ghost/ghost.log';
my @channels = ( '#RnR' );

POE::Session->create(
	GHost::IRC->inline_states(),
);

POE::Kernel->run();

sub _start : State {
	my $irc = POE::Component::IRC::State->spawn(
		Nick   => 'RnRHost',
		Server => 'irc.quakenet.org',
	);

	$irc->plugin_add( 'AutoJoin' => POE::Component::IRC::Plugin::AutoJoin->new(
		Channels => \@channels,
	));
	$irc->plugin_add( 'FollowTail' => POE::Component::IRC::Plugin::FollowTail->new( 
		filename => $ghostlog,
	));

	$irc->yield('connect');

	$_[HEAP]->{irc} = $irc;
	return;
}

sub irc_tail_input : State {
	my( $file, $input ) = @_[ARG0, ARG1];

	# filter out the msgs to what we want
	# [Tue Nov  3 20:55:11 2009] [LOCAL: USWest] [RnR_Bot] 5095 unique bnet users have joined this channel since the Clan's Creation
	# [Tue Nov  3 20:41:02 2009] [BNET: USWest] admin [JustBeingMiley] sent command [!Priv rnr]
	# [Tue Nov  3 20:39:31 2009] [GAME: death] admin [Death.strike] sent command [open] with payload [2]
	# [Tue Nov  3 21:18:03 2009] [GHOST] deleting game [Dota .64 -ARem Usa Pros]
	# [Tue Nov  3 21:19:21 2009] [WHISPER: USWest] [RnR_Bot] Happy Election Day RnRHost, your ping is 16.  Bot commands can be obtained @ http://clanrnr.com/pages/bot
	
	# we don't want those...
	# [Tue Nov  3 20:41:36 2009] [BNET: USWest] joining channel [Clan RnR]
	# [Tue Nov  3 20:39:28 2009] [BNET: USWest] joined channel [Clan RnR]
	if ( $input =~ /^\[[^\]]+\]\s+\[(\w+)\:\s+([^\]]+)\]\s+(.+)$/ ) {
		my( $type, $type2, $text ) = ( $1, $2, $3 );
		if ( $type eq 'LOCAL' ) {
			$_[KERNEL]->post( $_[SENDER], 'privmsg', $_, "CHANNEL: $text" ) for @channels;
		} elsif ( $type eq 'BNET' and $text =~ /^admin\s+(.+)$/ ) {
			$_[KERNEL]->post( $_[SENDER], 'privmsg', $_, "ADMIN: $1" ) for @channels;
		} elsif ( $type eq 'GAME' and $text =~ /^admin\s+(.+)$/ ) {
			$_[KERNEL]->post( $_[SENDER], 'privmsg', $_, "GAMEADMIN($type2): $1" ) for @channels;
		} elsif ( $type eq 'WHISPER' ) {
			$_[KERNEL]->post( $_[SENDER], 'privmsg', $_, "WHISPER: $text" ) for @channels;
		}
	}
		
	return;
}

sub irc_tail_error : State {
	my( $file, $errnum, $errmsg ) = @_[ARG0 .. ARG2];
	$_[KERNEL]->post( $_[SENDER], 'privmsg', $_, "<$file> ERROR: $errnum $errmsg" ) for @channels;
	return;
}
