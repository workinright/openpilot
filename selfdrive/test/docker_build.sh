#!/usr/bin/env bash
set -e

# To build sim and docs, you can run the following to mount the scons cache to the same place as in CI:
# mkdir -p .ci_cache/scons_cache
# sudo mount --bind /tmp/scons_cache/ .ci_cache/scons_cache

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

sudo bash -c "source $SCRIPT_DIR/basher ; CONFIG_DIGEST="$CONFIG_DIGEST" ; TOKEN="$TOKEN" ; REPO="$REPO" ; TAG="$TAG" ; IMAGE="$IMAGE" ; OUTPUT_DIR="$OUTPUT_DIR" ; basher_layers "/var/lib/docker2" "/var/lib/docker""

#if [ -n "$PUSH_IMAGE" ]; then
  output_arg="--output type=image,name=$DOCKER_REGISTRY/$DOCKER_IMAGE,compression=gzip,push=true"
#fi
echo output_arg $output_arg

DOCKER_BUILDKIT=1 docker buildx create --name mybuilder --driver docker-container --buildkitd-flags --use
DOCKER_BUILDKIT=1 docker buildx inspect --bootstrap

DOCKER_BUILDKIT=1 docker buildx build --provenance false --pull --builder mybuilder --platform $PLATFORM --load --cache-to type=inline --cache-from type=registry,ref=$REMOTE_TAG $output_arg -t $DOCKER_IMAGE:latest -t $REMOTE_TAG -t $LOCAL_TAG -f $OPENPILOT_DIR/$DOCKER_FILE $OPENPILOT_DIR
