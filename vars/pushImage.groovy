// Push Image: pushes to the registry.
//   pushImage(image: 'localhost:5000/frontend:12')                                  -> no login (local registry)
//   pushImage(image: 'user/frontend:12', credentialsId: 'docker')                   -> Docker Hub
//   pushImage(image: '<acct>.dkr.ecr.us-east-1.amazonaws.com/clouddevops/frontend:12',
//             ecrRegion: 'us-east-1')                                              -> ECR (EC2 IAM role)
def call(Map config) {
    if (!config.image) { error 'pushImage: "image" is required' }

    if (config.ecrRegion) {
        def registry = config.image.tokenize('/')[0]
        sh "aws ecr get-login-password --region ${config.ecrRegion} | docker login --username AWS --password-stdin ${registry}"
        sh "docker push ${config.image}"
    } else if (config.credentialsId) {
        withCredentials([usernamePassword(credentialsId: config.credentialsId,
                                          usernameVariable: 'REG_USER',
                                          passwordVariable: 'REG_PASS')]) {
            sh 'echo "$REG_PASS" | docker login -u "$REG_USER" --password-stdin'
            sh "docker push ${config.image}"
            sh 'docker logout'
        }
    } else {
        sh "docker push ${config.image}"
    }
}
