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

# TODO: credentials
if [ ! -e "$HOME/github_credentials" ] && [ ! -z "$AAA" ]
then
  echo "$AAA" > "$HOME/github_credentials"
fi

docker login ghcr.io $AAA
echo echo
cat $HOME/.docker/config.json | hexdump
echo echo

source $SCRIPT_DIR/docker_common.sh $1 "$TAG_SUFFIX"
source $SCRIPT_DIR/basher

basher_pull "/var/lib/docker" "/var/lib/docker2" "$PLATFORM" "$REMOTE_TAG" || true
# TODO: files are already identical, but now check are also the permissions matching!

if [ "$notrebuild_flag" != 1 ]
then
  sha256_docker="$(docker images --no-trunc --format "{{.ID}}" | cut -d':' -f2 | cut -d' ' -f1)"
  if [ "$sha256_docker" != "$MANIFEST_DIGEST" ]
  then
    docker buildx create --name mybuilder --driver docker-container --use
    docker buildx inspect --bootstrap

    # Zstandard uploading is broken in docker buildx! Therefore we build it this way, and use our hooks for the upload.
    docker buildx build
      --builder mybuilder \
      --platform $PLATFORM \
      --output type=docker,dest=$HOME/myimage.tar,compression=zstd,force-recompress=true \
      --progress=plain \
      -f $OPENPILOT_DIR/$DOCKER_FILE \
      $OPENPILOT_DIR

    # TODO: here load the just-built image

    if [ -n "$PUSH_IMAGE" ]
    then
      #basher_upload "myimage.tar" "$PLATFORM" "$REMOTE_TAG"

      # TODO: remove the need for this, proper argument parsing
      mkdir myimage
      tar -xf $HOME/myimage.tar -C myimage/
      basher_upload "myimage" "$PLATFORM" "$REMOTE_TAG"

      rm myimage.tar
    else
      echo "not pushing"
    fi
  fi
fi
