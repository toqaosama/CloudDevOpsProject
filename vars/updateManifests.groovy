// Update Manifests: sets the new image tag of one service in a kustomize overlay.
// updateManifests(service: 'frontend', tag: '12', overlay: 'k8s/overlays/local')
//
// In the overlay kustomization.yaml every image looks like:
//   - name: frontend
//     newName: localhost:5000/frontend
//     newTag: "11"
// Only the newTag line inside the block of the given service is changed.
def call(Map config) {
    if (!config.service) { error 'updateManifests: "service" is required' }
    if (!config.tag)     { error 'updateManifests: "tag" is required' }
    def file = "${config.overlay ?: 'k8s/overlays/local'}/kustomization.yaml"

    sh """
        sed -i '/- name: ${config.service}\$/,/newTag:/ s|newTag: .*|newTag: "${config.tag}"|' ${file}
        echo "---- ${file}"
        grep -A2 -- '- name: ${config.service}\$' ${file}
    """
}
