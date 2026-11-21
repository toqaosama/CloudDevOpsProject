// Build Image: docker build of one microservice.
// buildImage(image: 'localhost:5000/frontend:12', context: 'frontend')
def call(Map config) {
    if (!config.image)   { error 'buildImage: "image" is required' }
    if (!config.context) { error 'buildImage: "context" (service directory) is required' }

    sh "docker build -t ${config.image} ${config.context}"
}
