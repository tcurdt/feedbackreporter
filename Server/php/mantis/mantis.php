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

$g_bypass_headers = true;
require_once( MANTIS_PATH . 'core.php' );

class Mantis
{
	private $userID;
	private $client;

	public function __construct()
	{
		if( MANTIS_LOCAL ) {
			
			if( auth_attempt_script_login( MANTIS_USER, MANTIS_PWD ))
				$this->userID = auth_get_current_user_id();
				
		} else
			$this->client = new SoapClient( MANTIS_WSDL );
	}
	
	public function getProject( $proj )
	{
		if( MANTIS_LOCAL ) {

			$ret     = new StdClass;
			$ret->id = project_get_id_by_name( $proj );

		} else {
			
			$projects = $this->client->mc_projects_get_user_accessible( MANTIS_USER, MANTIS_PWD );

			foreach( $projects as $p )
				if( $p->name == $proj )
					$ret = $p;
		}

		return( $ret );
	}
	
	public function hasVersion( $projID, $version )
	{
		if( MANTIS_LOCAL )
			$ret = version_get_id( $version, $projID ) !== false;
		else {

			$vers = $this->client->mc_project_get_versions( MANTIS_USER, MANTIS_PWD, $projID );
			$ret  = false;
		
			foreach( $vers as $v )
				if( $v->name == $version ) {
					$ret = true;
					break;
				}
		}
			
		return( $ret );
	}
	
	public function addVersion( $projID, $version )
	{
		if( MANTIS_LOCAL ) {
			
			if( version_add( $projID, $version, true, $version )) {
				
				$t_version_id = version_get_id( $version, $projID );
				
				if ( !is_blank( $v_date_order )) {
					
					$t_version             = version_get( $t_version_id );
					$t_version->date_order = date( "Y-m-d H:i:s", strtotime( $v_date_order ));
					
					version_update( $t_version );
				}
			}
			
		} else {
			
			$this->client->mc_project_version_add( MANTIS_USER, MANTIS_PWD,
												   array(
														'name'		  => $version,
														'project_id'  => $projID,
														'description' => $version,
														'released'	  => true
												   ));			
		}
	}
	
	public function addIssue( $issue )
	{
		if( MANTIS_LOCAL ) {
			
			$t_bug_data                    = new BugData;
			$t_bug_data->project_id        = $issue->project->id;
			$t_bug_data->reporter_id       = $this->userID;
			$t_bug_data->priority          = $issue->priority[ 'id' ];
			$t_bug_data->severity          = $issue->severity[ 'id' ];
			$t_bug_data->reproducibility   = $issue->reproducibility[ 'id' ];
			$t_bug_data->status            = $issue->status[ 'id' ];
			$t_bug_data->resolution        = $issue->resolution[ 'id' ];
			$t_bug_data->projection        = $issue->projection[ 'id' ];
			$t_bug_data->category          = $issue->category;
			$t_bug_data->eta               = $issue->eta[ 'id' ];
			$t_bug_data->version           = $issue->version;
			$t_bug_data->view_state        = $issue->view_state[ 'id' ];
			$t_bug_data->summary           = $issue->summary;

			# extended info
			$t_bug_data->description            = $issue->description;
			$t_bug_data->additional_information = $issue->additional_information;

			# submit the issue
			$ret = bug_create( $t_bug_data );

			email_new_bug( $ret );

		} else
			$ret = $this->client->mc_issue_add( MANTIS_USER, MANTIS_PWD, $issue );
			
		return( $ret );
	}
	
	public function addAttachment( $bugID, $name, $str )
	{
		if( MANTIS_LOCAL ) {
				
			$tmpFile = tempnam( sys_get_temp_dir(), 'feedback' );
			
			file_put_contents( $tmpFile, $str );
		
			file_add( $bugID, $tmpFile, $name, 'text/plain' );

			unlink( $tmpFile );
			
		} else
			/*$this->client->mc_issue_attachment_add( MANTIS_USER, MANTIS_PWD, $bugID,
										  			$name, 'text/plain', $str ); */
			$this->client->mc_issue_attachment_add( MANTIS_USER, MANTIS_PWD, $bugID,
										  			$name, 'text/plain', base64_encode($str) ); 

	}
}
?>