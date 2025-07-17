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

#sudo apt-get -y install strace

args_add=
if [ -n "$PUSH_IMAGE" ]; then
  args_add=--push
  #docker push $REMOTE_TAG
  #docker tag $REMOTE_TAG $REMOTE_SHA_TAG
  #docker push $REMOTE_SHA_TAG
else
  args_add=--pull
fi

echo docker buildx build --output type=image,compression=zstd --provenance false --platform $PLATFORM --load --build-arg BUILDKIT_INLINE_CACHE=1 --cache-to type=registry,ref=$REMOTE_TAG,type=inline --cache-from type=registry,ref=$REMOTE_TAG -t $REMOTE_SHA_TAG -t $REMOTE_TAG -t $LOCAL_TAG -f $OPENPILOT_DIR/$DOCKER_FILE $OPENPILOT_DIR $args_add
DOCKER_BUILDKIT=1 docker buildx build --output type=image,compression=zstd --provenance false --platform $PLATFORM --load --build-arg BUILDKIT_INLINE_CACHE=1 --cache-to type=registry,ref=$REMOTE_TAG,type=inline --cache-from type=registry,ref=$REMOTE_TAG -t $REMOTE_SHA_TAG -t $REMOTE_TAG -t $LOCAL_TAG -f $OPENPILOT_DIR/$DOCKER_FILE $OPENPILOT_DIR $args_add
#DOCKER_BUILDKIT=1 docker buildx build --output type=image,compression=zstd --provenance false --platform $PLATFORM --load --build-arg BUILDKIT_INLINE_CACHE=1 --cache-to type=registry,ref=$REMOTE_TAG,type=inline --cache-from type=registry,ref=$REMOTE_TAG -t $DOCKER_IMAGE:latest -t $REMOTE_TAG -t $LOCAL_TAG -f $OPENPILOT_DIR/$DOCKER_FILE $OPENPILOT_DIR $args_add


