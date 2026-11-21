// Push Manifests: commits the updated overlay and pushes it to GitHub. Argo CD then syncs the cluster.
// pushManifests(files: 'k8s/overlays/local/kustomization.yaml', message: 'frontend -> 12',
//               branch: 'main', credentialsId: 'github')
//
// Three pipelines can push at the same time, so the push is retried after a rebase.
def call(Map config) {
    def branch        = config.branch ?: 'main'
    def credentialsId = config.credentialsId ?: 'github'
    def files         = config.files ?: 'k8s'
    def message       = "${config.message ?: 'Update manifests'} [skip ci]"

    withCredentials([usernamePassword(credentialsId: credentialsId,
                                      usernameVariable: 'GIT_USER',
                                      passwordVariable: 'GIT_TOKEN')]) {
        withEnv(["BRANCH=${branch}", "FILES=${files}", "MSG=${message}"]) {
            sh '''
                git config user.name  "jenkins"
                git config user.email "jenkins@ivolve.local"

                git add $FILES
                if git diff --cached --quiet; then
                    echo "No manifest change to push"
                    exit 0
                fi
                git commit -m "$MSG"

                REPO=$(git config --get remote.origin.url | sed 's|https://||')
                for i in 1 2 3 4 5; do
                    if git push "https://$GIT_USER:$GIT_TOKEN@$REPO" HEAD:"$BRANCH"; then
                        exit 0
                    fi
                    echo "push rejected, rebasing on the latest $BRANCH (try $i)"
                    git pull --rebase "https://$GIT_USER:$GIT_TOKEN@$REPO" "$BRANCH"
                    sleep 3
                done
                exit 1
            '''
        }
    }
}
