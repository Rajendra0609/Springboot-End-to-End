pipeline {
    agent any
    tools {
        maven 'maven'
    }
    environment {
        SCANNER_HOME = tool 'sonarqube'
        TRIVY_TIMEOUT = '10m'
    }
    stages {
        stage('mvn compile') {
            steps {
                sh 'mvn clean compile'
            }
        }
        stage('OWASP FS SCAN') {
            steps {
                script {
                    // Run OWASP Dependency Check
                    dependencyCheck additionalArguments: '--scan ./ --format HTML', odcInstallation: 'dpcheck'
                    
                    // Publish the Dependency Check report
                    dependencyCheckPublisher pattern: '**/dependency-check-report.html'
                    
                    // Archive the report file for access after the build
                    archiveArtifacts artifacts: '**/dependency-check-report.html'
                }
            }
        }
        stage('Lynis Security Scan') {
            steps {
                script {
                    // Execute the Lynis security scan and convert the output to HTML
                    sh 'lynis audit system | ansi2html > lynis-report.html'
                    
                    // Display the absolute path of the report in the Jenkins console output
                    def reportPath = "${env.WORKSPACE}/lynis-report.html"
                    echo "Chemin du rapport Lynis : ${reportPath}"
                    
                    // Archive the report file for access after the build
                    archiveArtifacts artifacts: 'lynis-report.html'
                }
            }
        }
        stage('SonarQube Analysis') {
            when {
                branch 'dev/chow'
            }
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=springboot \
                    -Dsonar.java.binaries=. \
                    -Dsonar.projectKey=Springboot'''
                }
            }
        }
        stage('Build') {
            steps {
                sh 'mvn clean'
                sh 'mvn package -DskipTests=true'
            }
        }
        stage('Archive Artifacts') {
            steps {
                // Archive the artifacts from the target directory
                archiveArtifacts artifacts: '**/target/*.jar', allowEmptyArchive: true
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Build & Push Docker Image') {
            environment {
                DOCKER_IMAGE = "daggu1997/spring-boot-app:${BUILD_NUMBER}"
                REGISTRY_CREDENTIALS = credentials('docker')
            }
            when {
                branch 'dev/chow'
            }
            steps {
                script {
                    sh 'docker build -t ${DOCKER_IMAGE} .'
                    def dockerImage = docker.image("${DOCKER_IMAGE}")
                    docker.withRegistry('https://index.docker.io/v1/', "docker") {
                        dockerImage.push()
                    }
                    sh 'docker rmi ${DOCKER_IMAGE}'
                }
            }
        }
        stage('Update Deployment File') {
    environment {
        GIT_REPO_NAME = "Springboot-end-to-end"
        GIT_USER_NAME = "Rajendra0609"
    }
    when {
        branch 'dev/chow'
    }
    steps {
        withCredentials([string(credentialsId: 'GITHUB_TOKEN', variable: 'GITHUB_TOKEN')]) {
            script {
                def releaseTag = "v0.${BUILD_NUMBER}.0" // Corrected tag format
                sh '''
                    git config user.email "rajendra.daggubati@gmail.com"
                    git config user.name "Rajendra0609"
                    git tag -a ${releaseTag} -m "Release ${releaseTag}"
                    git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} ${releaseTag}
                    
                    # Update deployment file with new image tag
                    imageTag=$(grep -oP '(?<=spring-boot-app:)[^ ]+' deployment.yml)
                    sed -i "s/spring-boot-app:${imageTag}/spring-boot-app:${BUILD_NUMBER}/" deployment.yml
                    git add deployment.yml
                    git commit -m "chore: Update deployment Image to version ${BUILD_NUMBER}"
                    git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:${releaseTag}
                '''
                echo "Created and pushed tag: ${releaseTag}"
            }
        }
    }
}

        stage('Cleanup Workspace') {
            steps {
                cleanWs()
                sh 'echo "Cleaned Up Workspace For Project"'
            }
        }
    }
}
