def applicationName = "statustest";
def applicationNameST = "${applicationName}-st";

pipeline{
    agent {
        label 'maven'
    }

 environment {
     BRANCH_NAME = "master"
     CLUSTER_NAME = "https://api.ca-central-1.starter.openshift-online.com:6443"
	 PROJECT_DEV="devopspoc" 
	 GITLAB_PROJECT_PATH="https://github.com/nitishsingla91/statustest.git"
	 OPENSHIFT_PROJECT_NAME="devopspoc"
	 JAR="statustest.war"
	 PORT='8110'
	
  }
  
    stages{
            stage('build') {
                steps{
                    sh script: "cd ${applicationName} && mvn -DskipTests clean package"   
                }
            }
            stage('build system tests') {
                steps{
                    sh script: "cd ${applicationNameST} && mvn clean package"   
                }
            }    
            stage('unit tests') {
                steps{
                    sh script: "cd ${applicationName} && mvn test"   
                }
            }    
            stage('integration tests') {
                steps{
                    sh script: "cd ${applicationName} && mvn failsafe:integration-test failsafe:verify"   
                }
            } 
            
			 stage('Create Image Builder') {
			  when {
				expression {
				  openshift.withCluster(CLUSTER_NAME) {
					  openshift.withProject( PROJECT_DEV ) {
							return (BRANCH_NAME == 'master' || BRANCH_NAME == 'development') && currentBuild.currentResult !='FAILURE' && !openshift.selector("bc",OPENSHIFT_PROJECT_NAME).exists();
							}
				  }
				}
			  }
			  steps {
				script {
				  openshift.withCluster(CLUSTER_NAME) {
					  openshift.withProject( PROJECT_DEV ) {
							openshift.newBuild("--name=${OPENSHIFT_PROJECT_NAME}", "--image-stream=redhat-openjdk18-openshift:1.1", "--binary")
							}
				  }
				}
			  }
		}

	
		stage('Build Image') {
	
			when{
				expression {
					return (BRANCH_NAME == 'master' || BRANCH_NAME == 'development') && currentBuild.currentResult !='FAILURE' ;
				}
		   }
          
        steps {
           echo "Pushing The JAR Into OpenShift OpenJDK-Container"
			echo "${currentBuild.currentResult}"
            script {
                openshift.withCluster( CLUSTER_NAME ) {
                    openshift.withProject( PROJECT_DEV ) {
                        openshift.selector("bc", OPENSHIFT_PROJECT_NAME).startBuild("--from-file=target/" + JAR,"--wait")
                    }
               }
			  
              }
          }
    	  
          post {
            success {
              archiveArtifacts artifacts: 'target/**.jar', fingerprint: true
            }
          }
        }
			
		stage('Tagging the Image') {
		
			when{
				expression {
					return (BRANCH_NAME == 'master' || BRANCH_NAME == 'development') && currentBuild.currentResult !='FAILURE' ;
				}
		    }
		  steps {
			script {
			  openshift.withCluster( CLUSTER_NAME ) {
			      openshift.withProject( PROJECT_DEV ) {
						openshift.tag(OPENSHIFT_PROJECT_NAME+":latest", OPENSHIFT_PROJECT_NAME+":dev")
					}
			  }
			}
		  }
		}
		
		 stage('Creating App in Openshift') {
			when{
				expression {
					return (BRANCH_NAME == 'master' || BRANCH_NAME == 'development') && currentBuild.currentResult !='FAILURE' &&  !openshift.selector("dc",OPENSHIFT_PROJECT_NAME).exists();
				}
		    }
		  steps {
			script {
			  openshift.withCluster( CLUSTER_NAME ) {
			      openshift.withProject( PROJECT_DEV ) {
						openshift.newApp(OPENSHIFT_PROJECT_NAME+":latest", "--name="+OPENSHIFT_PROJECT_NAME).narrow('svc').expose()
						
						
					}
			  }
			}
		  }
		}
		
		stage ('Verifying deployment'){
		
			 when {
				expression {
				  openshift.withCluster( CLUSTER_NAME ) {
					  openshift.withProject( PROJECT_DEV ) {
							return (BRANCH_NAME == 'master' || BRANCH_NAME == 'development') && currentBuild.currentResult !='FAILURE' && openshift.selector('dc', OPENSHIFT_PROJECT_NAME).exists() 
						}
				  }
				}
			  }
			  steps {
				script {
				  openshift.withCluster(CLUSTER_NAME) {
						openshift.withProject( PROJECT_DEV ){
							
							def latestDeploymentVersion = openshift.selector('dc',OPENSHIFT_PROJECT_NAME).object().status.latestVersion
							def rc = openshift.selector('rc', OPENSHIFT_PROJECT_NAME+"-${latestDeploymentVersion}")
							 timeout (time: 10, unit: 'MINUTES') {
								rc.untilEach(1){
									def rcMap = it.object()
									return (rcMap.status.replicas.equals(rcMap.status.readyReplicas))
								}
							 }
						}
					}
				  
				  
				  
				}
			  }
		
		} 
    }               
}