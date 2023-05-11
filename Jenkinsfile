pipeline {
    agent any
    options {
        // This is required if you want to clean before build
        skipDefaultCheckout(true)
    }
    parameters {
        string(
            name: 'PROJECT_NAME',
            defaultValue: 'apigateway'
        )
    }
    post {
        success {
            echo '============================ SUCCEED ============================'
            notify('success', params.PROJECT_NAME)
        }
        failure {
            echo '============================ FAILED ============================='
            buildDockerImage(commitId, params.PROJECT_NAME)
            notify('fail', params.PROJECT_NAME)
        }
    }
    stages {
        stage('Initial') {
            steps {
                echo "============================ INITIALIZATION ====================="
                cleanWs() // Clean before build
                checkout scm // We need to explicitly checkout from SCM here
                script {
                    echo 'get COMMIT_ID'
                    sh 'echo -n $(git rev-parse --short HEAD) > ./commitid'
                    commitId = readFile('./commitid')
                }
                script {
                    echo 'get BRANCH_NAME'
                    sh 'echo -n $(git rev-parse --symbolic-full-name --abbrev-ref HEAD) > ./branchname'
                    branchName = readFile('./branchname')
                }
                stash(name: 'ws', includes:'**,./commitid,./branchname') // stash this current workspace
                echo "${commitId}"
            }
        }
        stage('Build Image') {
            steps{
                echo "============================ BUILD IMAGE ========================"
                buildDockerImage(commitId, params.PROJECT_NAME)

                unstash 'ws'
            }
        }
        stage('Pushing Image') {
            steps{
                echo "============================ PUSHING IMAGE ======================"
                // TODO: push docker image to dockerhub or google contaner registry
                // removeDockerImage(commitId, params.PROJECT_NAME)
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

def gcrPush(){
    
}

def buildDockerImage(String commitId, String projectName){
    def opt = '--rm --no-cache --pull -t '
    withCredentials([string(credentialsId: 'registrypath', variable: 'REGISTRY')]) {
        opt += REGISTRY + '/'
    }
    opt += projectName + ':' + commitId

    sh '''
        OPT="'''+opt+'''"
        docker build $OPT .
        docker images
    '''
}

def removeDockerImage(String commitId, String projectName){
    def opt = '-f '
    withCredentials([string(credentialsId: 'registrypath', variable: 'REGISTRY')]) {
        opt += REGISTRY + '/'
    }
    opt += projectName + ':' + commitId

    sh '''
        OPT="'''+opt+'''"
        docker rmi $OPT
        docker images
    '''
}

def notify(String condition, String projectName) {
    def draftExecutable = ''
    withCredentials([string(credentialsId: 'discordwebhook', variable: 'WEBHOOK')]) {
        draftExecutable = ' --webhook-url=' + WEBHOOK 
    }    

    def url = '/blue/organizations/jenkins/apigateway/activity/'
    withCredentials([string(credentialsId: 'jenkinshost', variable: 'JENKINSHOST')]){
        url = JENKINSHOST + url
    }

    draftExecutable += ' --url=' + url
    draftExecutable += ' --title=' + projectName + '#' + currentBuild.number
    draftExecutable += ' --timestamp'
    
    draftExecutable += ' --color='
    if (condition == "success"){
        draftExecutable +='0x49FF00'
    }
    if (condition == "fail"){
        draftExecutable += '0xFF1E1E'
    }

    sh '''
        EXE="'''+draftExecutable+'''"
        bash ./jenkins/vendors/discord.sh/discord.sh $EXE
    '''

}
