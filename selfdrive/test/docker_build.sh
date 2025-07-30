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
source $SCRIPT_DIR/basher

basher_pull "/var/lib/docker" "/var/lib/docker2" "$PLATFORM" "$REMOTE_TAG:latest" || true
# TODO: files are already identical, but now check are also the permissions matching!

force_rebuild=1
force_push=1

if [ "$notrebuild_flag" != 1 ] || [ "$force_rebuild" = 1 ]
then
  sha256_docker="$(docker images --no-trunc --format "{{.ID}}" | cut -d':' -f2 | cut -d' ' -f1)"
  if [ "$sha256_docker" != "$MANIFEST_DIGEST" ] || [ "$force_rebuild" = 1 ]
  then
    docker buildx create --name mybuilder --driver docker-container --use
    docker buildx inspect --bootstrap

    IMAGE_PATH="$HOME/myimage.tar"

    # Zstandard uploading is broken in docker buildx! Therefore we build it this way, and use our hooks for the upload.
    docker buildx build \
      --builder mybuilder \
      --platform $PLATFORM \
      --output type=docker,dest="$IMAGE_PATH",compression=zstd,force-recompress=true \
      --progress=plain \
      -f $OPENPILOT_DIR/$DOCKER_FILE \
      $OPENPILOT_DIR

    # TODO: here load the just-built image

    if [ -n "$PUSH_IMAGE" ] || [ "$force_push" = 1 ]
    then
      basher_push "$IMAGE_PATH" "$REMOTE_TAG"
      rm "$IMAGE_PATH"
    else
      echo "not pushing"
    fi
  fi
fi
