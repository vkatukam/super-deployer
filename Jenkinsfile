library 'stable' 
pipeline {
    agent {
        label 'linux'
    }
    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 5, unit: 'MINUTES')
    }
    parameters {
        string( name: 'GROUP_ID', defaultValue: 'se.telenor.services')
        string( name: 'ARTIFACT_ID', defaultValue: 'secretsDebugger-service')
        string( name: 'VERSION', defaultValue: '1.0.1-SNAPSHOT')
        string( name: 'CLASSIFIER', defaultValue: '')
        string( name: 'GROUP', defaultValue: 'debug')
        string( name: 'SERVICE_NAME', defaultValue: 'secretsdebugger')
        string( name: 'ARGS', defaultValue: '')
        choice( name: 'ENVIRONMENT', choices: ['test1', 'test2', 'test3', 'test4', 'ft', 'sit', 'sat', 'prod'])
        string( name: 'BASE_IMAGE', defaultValue: 'openjdk:8u131-jre-alpine')    
        booleanParam( name: 'USE_CURRENTLY_PUBLISHED_IMAGE', defaultValue: false)
        booleanParam( name: 'HAS_HEALTHCHECK', defaultValue: false )
    }
    stages {
        stage('Prepare Environment'){
            steps {
                cleanWs()
                checkout scm
                script {
                    env.BUILD_USER = getBuildUserName()
                    env.BUILD_USER_EMAIL = getBuildUserEmail()
                    env.DEPLOYED_LAST = getCurrentTime()
                    env.APP_SERVER = getServer(params.ENVIRONMENT)
                    env.DEPLOYED_SERVICE_NAME = deployedServiceName(params.SERVICE_NAME, params.ENVIRONMENT)
                    env.DOCKER_REGISTRY_PORT = getDockerRegistryPortByVersion(params.VERSION, params.ENVIRONMENT)
                }
            }
        }
        stage('Reject snapshot versions to prod'){
            when {
                expression { params.ENVIRONMENT == 'prod' && params.VERSION.endsWith('SNAPSHOT') }
            }
            steps {
                error """
                 ============= SNAPSHOT version detected ==============
                   SNAPSHOT versions should never be deployed to prod
                 You need to make a proper release with a sharp version 
                          Failing job because of attempt to deploy
                           ${GROUP_ID}:${ARTIFACT_ID}:${VERSION}
                                          into
                                       production
                 ======================================================
                """
            }
        }
        stage('Fetch Artifact') {
            steps {
                echo """
                    ============== Fetching Artifact ====================
                        ${GROUP_ID}:${ARTIFACT_ID}:${VERSION}
                                        from Nexus
                            http://nexus.se.telenor.net/maven-public
                    =====================================================
                """
                sh "./downloadArtifact.sh ${GROUP_ID} ${ARTIFACT_ID} ${VERSION} jar ${SERVICE_NAME}.jar ${params.CLASSIFIER}"
            }
        }
        stage('Import service.yml') {
            steps {
                importServiceYaml("${SERVICE_NAME}.jar")
            }
        }
        stage('Customize Jvm') {
            steps {
                customizeJvm("${BASE_IMAGE}")
            }
        }           
        stage('Resolve Docker Secrets') {
            when {
                expression { env.SECRETS }
            }
            steps {
                echo '''
                    ============ Resolving Docker Secrets ================
                '''
                testDockerSecrets(env.APP_SERVER, env.DEPLOYED_SERVICE_NAME, env.SECRETS)    
            }
        }
        stage('Build Image') {
            when {
                expression { return !params.USE_CURRENTLY_PUBLISHED_IMAGE }
            }
            steps { 
                expandTokens(['build-docker-image.sh', 'entrypoint.sh', 'Dockerfile'])
                echo '========== Packaging Image ==========='
                sh './build-docker-image.sh'
                echo """
                    ============ Image published to Nexus ================
                            Run locally using the following command
            docker run nexus.se.telenor.net:5080/bapi/${ENVIRONMENT}/$SERVICE_NAME:${version} ${ARGS}
                    ======================================================
                """
            }
        }
        stage('Rolling Deployment') {
            when {
                expression { params.HAS_HEALTHCHECK }
            }
            steps {
                expandTokens(['rolling-deploy-service.sh'])
                sshagent (credentials: ['DOCKER_CLUSTER_DEPLOYMENT_KEY']) {
                    sh './rolling-deploy-service.sh'
                }
            }
        }
        stage('Regular Deployment') {
            when {
                expression { !params.HAS_HEALTHCHECK }
            }
            steps {
                expandTokens(['deploy-service.sh'])
                sshagent (credentials: ['DOCKER_CLUSTER_DEPLOYMENT_KEY']) {
                    sh './deploy-service.sh'
                }
            }
        }
    }
    post {
        always {
            email getBuildUserEmail()
        }
        success {
            script {
                try {
                    expandTokens(['confluence-template.html'])
                    publishConfluence(editorList: [confluenceWritePage(confluenceFile('confluence-template.html'))],
                        labels: 'environment-status-bapi, environment-status, ${ENVIRONMENT}, ${SERVICE_NAME}', 
                        pageName: '${SERVICE_NAME}-${ENVIRONMENT}', 
                        parentId: 582453045, 
                        siteName: 'jira.se.telenor.net', 
                        spaceName: 'DEVSUP')
                    slack(webhookId: 'DEPLOYMENT_LOG_SLACK_URL', 
                        message: ":heavy_check_mark: <mailto:${getBuildUserEmail()}|${getBuildUserName()}> deployed *${SERVICE_NAME}* into *${ENVIRONMENT}* <${currentBuild.absoluteUrl}/console|:information_source:>")
                } catch (any) {
                    echo '========== Unable to publish information about deployment to confluence or slack ======'
                    echo any.message
                }
            }
        }
        failure {
            email leadDeveloper()
            script {
                try {
                    slack(webhookId: 'DEPLOYMENT_LOG_SLACK_URL', 
                          message: ":x: <mailto:${getBuildUserEmail()}|${getBuildUserName()}> *failed* to deploy  *${SERVICE_NAME}* into *${ENVIRONMENT}* <${currentBuild.absoluteUrl}/console|:information_source:>")
                } catch (any) {
                    echo '========== Unable to publish information about deployment failure to slack ======'
                    echo any.message 
                }
            }
        }
    }
}
