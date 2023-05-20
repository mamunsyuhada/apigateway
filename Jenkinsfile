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
            sh '''
                cat ./jenkins/scripts/deployed.sh | \\
                    BUILD_NUMBER="'''+BUILD_NUMBER+'''" \\
                    COMMIT_ID="'''+commitId+'''" \\
                    BRANCH="'''+BRANCH_NAME+'''" \\
                    envsubst | \\
                    bash -f
            '''
        }
        failure {
            echo '============================ FAILED ============================='
            sh '''
                cat ./jenkins/scripts/failed.sh | \\
                    BUILD_NUMBER="'''+BUILD_NUMBER+'''" \\
                    COMMIT_ID="'''+commitId+'''" \\
                    BRANCH="'''+BRANCH_NAME+'''" \\
                    envsubst | \\
                    bash -f
            '''
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
                echo "================== LINTING & UNIT TESTING ========================"
                unstash 'ws'
                npm 'install'
                npm 'run lint'
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
                        sh '''
                            cat ./jenkins/scripts/needaproval.sh | \\
                                BUILD_NUMBER="'''+BUILD_NUMBER+'''" \\
                                COMMIT_ID="'''+commitId+'''" \\
                                BRANCH="'''+BRANCH_NAME+'''" \\
                                envsubst | \\
                                bash -f
                        '''
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
                }
            }
        }
        stage('Deployment to Kubernetes Environment'){
            when { expression { BRANCH_NAME == 'dev' || BRANCH_NAME == 'prod' } }
            steps {
                echo "============================ DEPLOY TO KUBERNETES ENV ==========="
                script {
                    withCredentials([
                        string(credentialsId: 'swith_to_prod_cluster', variable: 'swith_to_prod_cluster'),
                        string(credentialsId: 'swith_to_dev_cluster', variable: 'swith_to_dev_cluster')
                    ]){
                        if (env.BRANCH_NAME == 'prod'){
                            sh '${swith_to_prod_cluster} && kubectl config get-contexts'
                        }

                        if (env.BRANCH_NAME == 'dev'){
                            sh '${swith_to_dev_cluster} && kubectl config get-contexts'
                        }
                    }
                    sh '''
                        kustomize build . | ENV_STAGE="'''+env.BRANCH_NAME+'''" COMMITID="'''+commitId+'''" envsubst | kubectl apply -f -
                    '''
                }
            }
        }
    }
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

def getRegistryRepo(){
    def repository = ''
    withCredentials([
        string(credentialsId: 'registrypath', variable: 'REGISTRY')
    ]) {
        repository += REGISTRY + '/' + params.PROJECT_NAME
    }
    return repository
}
