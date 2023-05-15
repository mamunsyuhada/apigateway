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
        stage('Unit Testing') {
            steps{
                echo "============================ UNIT TESTING ========================"
                unstash 'ws'
                npm 'install'
                npm 'run test:cov'
            }
        }
        stage('Build Image') {
            agent { label "docker" }
            steps{
                echo "============================ BUILD IMAGE ========================"
                unstash 'ws'
                buildDockerImage(commitId)
            }
        }
        stage('Pushing Image') {
            when { expression { BRANCH_NAME == 'dev' || BRANCH_NAME == 'prod' } }
            agent { label "docker" }
            steps{
                script {
                    def envStage = BRANCH_NAME

                    echo "============================ PUSHING IMAGE TO ${envStage} ======================"
                    if (env.BRANCH_NAME == 'prod'){
                        def userInput = input(
                            message: 'Deploy to production ?',
                            parameters: [
                                [
                                    $class: 'ChoiceParameterDefinition',
                                    choices: ['no','yes'].join('\n'),
                                    name: 'input',
                                    description: 'Menu - select box option'
                                ]
                            ]
                        ) 
                        if( "${userInput}" == "no"){
                            sh 'exit 1'
                        }
                    }

                    updateDockerImageWithStage(commitId, envStage)
                    pushDockerImage(commitId, envStage)
                    sh 'docker image prune'
                }
            }
        }
        stage('Deployment to Kubernetes Environment'){
            when { expression { BRANCH_NAME == 'dev' || BRANCH_NAME == 'prod' } }
            agent { label "kubectl" }
            steps {
                echo "============================ DEPLOY TO KUBERNETES ENV ==========="
                script {
                    withCredentials([
                        string(credentialsId: 'apigateway_domain', variable: 'DOMAIN')
                    ]){
                        def imageTarget = getRegistryRepo() + ':' + commitId 
                        echo "${imageTarget}"
                        def domain = BRANCH_NAME + '.' + DOMAIN

                        sh '''
                            kubectl
                        '''
                    }
                }
            }
        }
    }
}

def getRegistryRepo(){
    def repository = ''
    withCredentials([
        string(credentialsId: 'registrypath', variable: 'REGISTRY')
    ]) {
        repository += REGISTRY + '/' + params.PROJECT_NAME
    }
    return repository
}

def pushDockerImage(String commitId, String envStage){
    def repository = getRegistryRepo()
    def stageTagOpt = repository + ':' + envStage
    sh '''
        STAGE_TAG_OPT="'''+stageTagOpt+'''"
        docker push $STAGE_TAG_OPT
    '''

    def commitIdTagOpt = repository + ':' + commitId
    sh '''
        COMMIT_ID_TAG_OPT="'''+commitIdTagOpt+'''"
        docker push $COMMIT_ID_TAG_OPT
    '''
}

def updateDockerImageWithStage(String commitId, String envStage){
    def repository = getRegistryRepo()

    // Remove stage old
    def rmiOpt = repository + ':' + envStage
    sh '''
        RMI_OPT="'''+rmiOpt+'''"
        docker rmi -f $RMI_OPT &> /dev/null
    '''

    // Update image (copy image from latest commit)
    def updateOpt = 'tag ' + repository + ':' + commitId + ' '
    updateOpt += repository + ':' + envStage
    sh '''
        UPDATE_OPT="'''+updateOpt+'''"
        docker image $UPDATE_OPT
    '''
}

def buildDockerImage(String commitId){
    def opt = '--rm --no-cache --pull -t ' + getRegistryRepo() + ':' + commitId

    sh '''
        OPT="'''+opt+'''"
        docker build $OPT .
        docker images
    '''
}

def removeDockerImage(String commitId){
    def opt = '-f ' + getRegistryRepo() + ':' + commitId

    sh '''
        OPT="'''+opt+'''"
        docker rmi $OPT
        docker images
    '''
}

def notify(String condition, String projectName) {
    def draftExecutable = ''
    def url = '/blue/organizations/jenkins/apigateway/activity/'
    withCredentials([
        string(credentialsId: 'discordwebhook', variable: 'WEBHOOK'),
        string(credentialsId: 'jenkinshost', variable: 'JENKINSHOST')
    ]) {
        draftExecutable = ' --webhook-url=' + WEBHOOK
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
