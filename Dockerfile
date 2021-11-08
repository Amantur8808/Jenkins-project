pipeline{

	agent any

	environment {
		DOCKERHUB_CREDENTIALS=credentials('dockerhub')
	}

	stages {

		stage('Build') {

			steps {
				sh 'docker build -t tynchtyk/project:latest .'
			}
		}

				
                stage('Login') {

                        steps {
                            sh 'docker login -p $DOCKERHUB_CREDENTIALS_PSW -u $DOCKERHUB_CREDENTIALS_USR'
                        }
                }

		stage('Push') {

			steps {
				sh 'docker push tynchtyk/project:latest'
			}
		}
		
        stage ('Deploy to staging') {
            steps {
                withCredentials ([usernamePassword(credentialsId: 'webserver_login', usernameVariable: 'USERNAME', passwordVariable: 'USERPASS')]) {
                    script {
                        sh "sshpass -p '$USERPASS' -v ssh -o StrictHostKeyChecking=no $USERNAME@${env.dev_ip} \"docker pull tynchtyk/project\""
                        try {
                            sh "sshpass -p '$USERPASS' -v ssh -o StrictHostKeyChecking=no $USERNAME@${env.dev_ip} \"docker stop project\""
                            sh "sshpass -p '$USERPASS' -v ssh -o StrictHostKeyChecking=no $USERNAME@${env.dev_ip} \"docker rm project\""
                        } catch (err) {
                            echo: 'caught error: $err'
                        }
                        sh "sshpass -p '$USERPASS' -v ssh -o StrictHostKeyChecking=no $USERNAME@${env.dev_ip} \"docker run --name project -p 8080:80 -d tynchtyk/project\""
                    }
                }
            }
        }
        
        stage ('Deploy to production') {
            steps {
                input 'Deploy to Production'
                milestone(1)
                withCredentials ([usernamePassword(credentialsId: 'webserver_login', usernameVariable: 'USERNAME', passwordVariable: 'USERPASS')]) {
                    script {
                        sh "sshpass -p '$USERPASS' -v ssh -o StrictHostKeyChecking=no $USERNAME@${env.prod_ip} \"docker pull tynchtyk/project\""
                        try {
                            sh "sshpass -p '$USERPASS' -v ssh -o StrictHostKeyChecking=no $USERNAME@${env.prod_ip} \"docker stop project\""
                            sh "sshpass -p '$USERPASS' -v ssh -o StrictHostKeyChecking=no $USERNAME@${env.prod_ip} \"docker rm project\""
                        } catch (err) {
                            echo: 'caught error: $err'
                        }
                        sh "sshpass -p '$USERPASS' -v ssh -o StrictHostKeyChecking=no $USERNAME@${env.prod_ip} \"docker run --name project -p 8080:80 -d tynchtyk/project\""
                    }
                }
            }
        }	
		
	}
        
        post {
            always {
                sh 'docker logout'
            }
        }

}
