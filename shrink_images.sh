#!/bin/bash

set -e

FINISHED_MARKER=output/.finished-generating
function shutdown_when_finished() {
    # wait until marker file is created
    while [ ! -f $FINISHED_MARKER ]; do
    sleep 1
    done

    docker-compose -f rsync-image-diff.docker-compose.yml down
}

echo "Usage shrink_images.sh <old_image> <new_image> <resultant_image> [RESTRICT_DIFF_TO_PATH]"
export RESTRICT_DIFF_TO_PATH=$4
export OLD_IMAGE=$1
export NEW_IMAGE=$2


rm -rf $FINISHED_MARKER

# run shutdown_when_finished() in background
shutdown_when_finished &

docker-compose -f rsync-image-diff.docker-compose.yml up

wait # wait for shutdown_when_finished() to finish

docker-compose -f shell.docker-compose.yml -f process-image-diff.docker-compose.yml run --rm shell ./generate-dockerfile.sh
cd output; docker build -t $3 .; cd ..
