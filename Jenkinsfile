pipeline {
    agent any
    options {
        // This is required if you want to clean before build
        skipDefaultCheckout(true)
    }
    post {
        success {
            echo '============================ SUCCEED ============================'
            notify('success')
        }
        failure {
            echo '============================ FAILED ============================='
            notify('fail')
        }
    }
    stages {
        stage('Initial') {
            steps {
                echo "============================ INITIALIZATION ====================="
                cleanWs() // Clean before build
                checkout scm // We need to explicitly checkout from SCM here
            }
        }
        stage('Build Image') {
            steps{
                echo "============================ BUILD IMAGE ========================"
                // TODO: build docker image
            }
        }
        stage('Pushing Image') {
            steps{
                echo "============================ PUSHING IMAGE ======================"
                // TODO: push docker image to dockerhub or google contaner registry
            }
        }
        stage('Deployment to Kubernetes Environment'){
            steps {
                echo "============================ DEPLOY TO KUBERNETES ENV ==========="
                // branch conditional (dev, release, prod)
                // TODO: deploy app to kubernetes env
            }
        }
    }
}


def notify(String condition) {
    def url = '/blue/organizations/jenkins/api-gateway/detail/api-gateway/'
    withCredentials([string(credentialsId: 'jenkinshost', variable: 'JENKINSHOST')]){
        url = JENKINSHOST + url
    }

    def draftExecutable = ''
    withCredentials([string(credentialsId: 'discordwebhook', variable: 'WEBHOOK')]) {
        draftExecutable = ' --webhook-url=\"' + WEBHOOK + '\"' 
    }

    draftExecutable += ' --url=\"' + url + currentBuild.number + '/pipeline\"'
    draftExecutable += ' --title=apigateway#' + currentBuild.number
    draftExecutable += ' --timestamp'
    
    draftExecutable += ' --color='
    if (condition == "success"){
        draftExecutable +='\"0x49FF00\"'
    }
    if (condition == "fail"){
        draftExecutable += '\"0xFF1E1E\"'
    }

    sh '''
        EXE="'''+draftExecutable+'''"
        bash ./jenkins/vendors/discord.sh/discord.sh $EXE
    '''

}
