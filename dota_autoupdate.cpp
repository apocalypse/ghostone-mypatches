#define DOTA_AUTOUPDATE 1
#define DOTA_AUTOUPDATE_CMD "dota_update.pl"

bool CheckDOTAUpdate() {
	int i;
	if ( ! system( NULL ) ) {
		// Hmpf, we cannot execute commands!
		return FALSE;
	}

	i = system( DOTA_AUTOUPDATE_CMD );
	if ( i == 0 ) {
		// exitval of 0 means successfully updated, all others is error
		
		// Hmpf, issue a "!load dota"

		// Hmpf, announce dota update in channel!

		return TRUE;
	}

	return FALSE;
}
