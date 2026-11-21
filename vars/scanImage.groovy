// Scan Image: Trivy scan for HIGH/CRITICAL vulnerabilities.
// scanImage(image: 'localhost:5000/frontend:12', failOnFindings: false)
def call(Map config) {
    if (!config.image) { error 'scanImage: "image" is required' }

    def exitCode = config.failOnFindings ? 1 : 0
    sh """
        trivy image --no-progress --scanners vuln \
          --severity HIGH,CRITICAL --exit-code ${exitCode} \
          --format table ${config.image}
    """
}
