#!/usr/bin/env bash
set -e

# To build sim and docs, you can run the following to mount the scons cache to the same place as in CI:
# mkdir -p .ci_cache/scons_cache
# sudo mount --bind /tmp/scons_cache/ .ci_cache/scons_cache

echo ARGS $@

SCRIPT_DIR=$(dirname "$0")
OPENPILOT_DIR=$SCRIPT_DIR/../../
if [ -n "$TARGET_ARCHITECTURE" ]; then
  PLATFORM="linux/$TARGET_ARCHITECTURE"
  TAG_SUFFIX="-$TARGET_ARCHITECTURE"
else
  PLATFORM="linux/$(uname -m)"
  TAG_SUFFIX=""
fi

source $SCRIPT_DIR/docker_common.sh $1 "$TAG_SUFFIX"

docker pull ghcr.io/workinright/openpilot-base:latest
#docker tag ghcr.io/workinright/openpilot-base121:latest ghcr.io/workinright/openpilot-base:latest
docker tag ghcr.io/workinright/openpilot-base:latest $REMOTE_SHA_TAG
docker tag ghcr.io/workinright/openpilot-base:latest $LOCAL_TAG

#DOCKER_BUILDKIT=1 docker buildx create --name mybuilder --driver docker-container --buildkitd-flags --use
#DOCKER_BUILDKIT=1 docker buildx inspect --bootstrap

#docker login -u workinright -p

#docker buildx create --name mybuilder --driver docker-container \
#  --driver-opt network=host \
#  --driver-opt "docker-config=$HOME/.docker" \
#  --use

#DOCKER_BUILDKIT=1 docker buildx build --builder mybuilder --output type=image,name=ghcr.io/workinright/openpilot-base,push=true,compression=gzip,compression-level=1,force-compression=true --provenance false --pull --platform $PLATFORM --load --cache-to type=inline --cache-from type=registry,ref=$REMOTE_TAG -t workinright/openpilot-base:latest -f $OPENPILOT_DIR/$DOCKER_FILE $OPENPILOT_DIR
#exit 1

#if [ -n "$PUSH_IMAGE" ]; then
#  docker push $REMOTE_TAG
#  docker tag $REMOTE_TAG $REMOTE_SHA_TAG
#  docker push $REMOTE_SHA_TAG
#fi
