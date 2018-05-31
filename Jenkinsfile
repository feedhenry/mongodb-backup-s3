#!groovy

// https://github.com/feedhenry/fh-pipeline-library
@Library('fh-pipeline-library') _

stage('Trust') {
    enforceTrustedApproval()
}

fhBuildNode(['label': 'openshift']) {

    final String COMPONENT = "backups"
    final String VERSION = "1.0.0"
    final String BUILD = env.BUILD_NUMBER
    final String DOCKER_HUB_ORG = "rhmap"
    final String DOCKER_HUB_REPO = COMPONENT
    final String CHANGE_URL = env.CHANGE_URL

    stage('Build Image') {
        final Map params = [
                fromDir: '.',
                buildConfigName: COMPONENT,
                imageRepoSecret: "dockerhub",
                outputImage: "docker.io/${DOCKER_HUB_ORG}/${DOCKER_HUB_REPO}:${VERSION}-${BUILD}"
        ]
        buildWithDockerStrategy params
        archiveArtifacts writeBuildInfo('rhmap-backups', "${VERSION}-${BUILD}")
    }

    if (env.BRANCH_NAME && env.BRANCH_NAME == 'master') {
        stage('Build Latest Image') {
            final Map params = [
                    fromDir: '.',
                    buildConfigName: COMPONENT,
                    imageRepoSecret: "dockerhub",
                    outputImage: "docker.io/${DOCKER_HUB_ORG}/${DOCKER_HUB_REPO}:latest"
            ]
            buildWithDockerStrategy params
            archiveArtifacts writeBuildInfo('rhmap-backups', "${VERSION}-${BUILD}")
        }
    }
}
