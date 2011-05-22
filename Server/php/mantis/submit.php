<?php
	/*
	 * Copyright 2009, Simone Tellini, http://tellini.info
	 *
	 * Licensed under the Apache License, Version 2.0 (the "License");
	 * you may not use this file except in compliance with the License.
	 * You may obtain a copy of the License at
	 *
	 *     http://www.apache.org/licenses/LICENSE-2.0
	 *
	 * Unless required by applicable law or agreed to in writing, software
	 * distributed under the License is distributed on an "AS IS" BASIS,
	 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 * See the License for the specific language governing permissions and
	 * limitations under the License.
	 */

	require_once( 'config.php' );
	require_once( 'mantis.php' );

	$issue    = new StdClass;
	$crashlog = explode( 'Binary Images:', $_POST[ 'crashes' ] );

	$issue->summary                = BUG_SUMMARY;
	$issue->severity               = array( 'id' => 70 );
	$issue->category               = BUG_CATEGORY;
	$issue->description            = 'From: ' . $_POST[ 'email' ] . "\n\n" . $_POST[ 'comment' ];
	$issue->additional_information = $crashlog[ 0 ];
	$issue->priority               = array( 'id' => 10 );
	$issue->status                 = array( 'id' => 10 );
	$issue->reproducibility        = array( 'id' => 70 );
	$issue->resolution             = array( 'id' => 10 );
	$issue->projection             = array( 'id' => 10 );
	$issue->eta                    = array( 'id' => 10 );
	$issue->view_state             = array( 'id' => 50 );
	$issue->version                = $_POST[ 'version' ];

	if( empty( $issue->description ))
		$issue->description = 'Crashed.';

	$attachments = array( 'crashes', 'console', 'preferences', 'exception', 'shell', 'system' );

	try {
		$mantis = new Mantis();
		
		$issue->project = $mantis->getProject( $_REQUEST[ 'project' ] );
	
		if( !$mantis->hasVersion( $issue->project->id, $issue->version ))
			$mantis->addVersion( $issue->project->id, $issue->version );
				
		$id = $mantis->addIssue( $issue );

		foreach( $attachments as $f ) {

			$str = $_POST[ $f ];

			if( !empty( $str ))
				$mantis->addAttachment( $id, $f . '.txt', $str ); 
		}
	}
	catch( SoapFault $e ) {
		print( 'ERR An error occurred while storing the report' );
	}
?>