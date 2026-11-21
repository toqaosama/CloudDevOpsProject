// Delete Image Locally: frees disk space on the agent after the push.
// deleteImageLocally(image: 'localhost:5000/frontend:12')
def call(Map config) {
    if (!config.image) { error 'deleteImageLocally: "image" is required' }

    sh "docker rmi ${config.image} || true"
    sh 'docker image prune -f'
}
