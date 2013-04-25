<?php
	// the reporter of the issues
	define( 'MANTIS_USER',	'user' );
	define( 'MANTIS_PWD',	'password' );
	
	// if true, this script is running on the same machine hosting mantis,
	// so we can use its API directly
	define( 'MANTIS_LOCAL',	true );
	// path to your mantis installation, only needed if MANTIS_LOCAL is true
	define( 'MANTIS_PATH',	dirname( __FILE__ ) . '/../mantis/' );

	// used only when MANTIS_LOCAL is false. The SOAP extension is required.
	define( 'MANTIS_URL',	'http://www.yoursite.com/mantis/' );
	define( 'MANTIS_WSDL',	MANTIS_URL . 'api/soap/mantisconnect.php?wsdl' );

	// constants for the reports
	define( 'BUG_SUMMARY',	'Crash report' );
	define( 'BUG_CATEGORY',	'Feedback' );
?>