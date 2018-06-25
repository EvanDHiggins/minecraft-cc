set -o xtrace


if [[ $# -ne 1 ]]; then
    echo 'Run with: ./deploy.sh $DEPLOY_PATH'

    exit 1
fi

for file in *.lua; do
    DEPLOY_PATH='~/Library/Application Support/technic/modpacks/tekkitmain/saves/cctest/computer/0/'
    DEPLOY_PATH="${HOME}/Library/Application Support/technic/modpacks/tekkitmain/saves/cctest/computer/0"

    cp ${file} "${DEPLOY_PATH}"
done
