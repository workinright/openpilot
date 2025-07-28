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

if [ ! -e "$HOME/github_credentials" ] && [ ! -z "$AAA" ]
then
  echo "$AAA" > "$HOME/github_credentials"
fi

echo echo
echo docker buildx build --provenance false --pull --platform $PLATFORM --load --cache-to type=inline --cache-from type=registry,ref=$REMOTE_TAG -t $DOCKER_IMAGE:latest -t $REMOTE_TAG -t $LOCAL_TAG -f $OPENPILOT_DIR/$DOCKER_FILE $OPENPILOT_DIR
echo echo

source $SCRIPT_DIR/docker_common.sh $1 "$TAG_SUFFIX"
source $SCRIPT_DIR/basher

basher_pull "/var/lib/docker" "/var/lib/docker2" "$PLATFORM" || true
echo notrebuild_flag $notrebuild_flag

sha256_10="$(docker images --no-trunc --format "{{.ID}}" | cut -d':' -f2 | cut -d' ' -f1)"
#echo sha256_10 $sha256_10




flags=
##if [ -n "$PUSH_IMAGE" ] && [ "$sha256_10" != "$sha256_11" ] && [ "$use_zstd" = 1 ]
##then
  #mkdir ./myimage
  flags="--output type=image,dest=$HOME/myimage.tar,compression=uncompressed,force-recompress=true"
##fi

if [ ! "$notrebuild_flag" = 1 ]
then

#####date
#output="$(DOCKER_BUILDKIT=1 docker buildx build --progress=plain --load --platform $PLATFORM --cache-to type=inline --cache-from type=registry,ref=$REMOTE_TAG -t ghcr.io/workinright/openpilot-base -f $OPENPILOT_DIR/$DOCKER_FILE $OPENPILOT_DIR 2>&1)"
#####date
#echo output $output
#echo output $output
#sha256_11="$(echo "$output" | grep sha256 | tail -n1 | cut -d':' -f2 | cut -d' ' -f1)" || true

#echo sha1
#echo "$sha256_10"
#echo sha12
#echo "$sha256_11"
#echo shaend

if [ -n "$PUSH_IMAGE" ] && [ "$sha256_10" != "$sha256_11" ]
then
  ##if [ "$use_zstd" = 1 ]
  #then
    # Zstandard uploading is broken in docker buildx!

    #wget -O - "https://github.com/oras-project/oras/releases/download/v1.2.3/oras_1.2.3_linux_amd64.tar.gz" \
    #  | pigz -d | tar xf -

  DOCKER_BUILDKIT=1 docker buildx create --name mybuilder --driver docker-container --use
  DOCKER_BUILDKIT=1 docker buildx inspect --bootstrap
    
    #output2="$(
    DOCKER_BUILDKIT=1 docker buildx build --builder mybuilder --output type=docker,dest=$HOME/myimage.tar,compression=zstd,force-recompress=true --platform $PLATFORM --progress=plain -f $OPENPILOT_DIR/$DOCKER_FILE $OPENPILOT_DIR
    #2>&1)"
    #echo output2 $output2

    #####ls
    mkdir myimage
    tar -xf $HOME/myimage.tar -C myimage/
    ######rm $HOME/myimage.tar

    #####stat myimage || true
    #####find myimage
    #####ls myimage
    #####file -bi myimage/blobs/sha256/*
    #####du -sh myimage/blobs/sha256/*
    #####zstd -l file -bi myimage/blobs/sha256/*
    #sha256sum myimage/blobs/sha256/*

  #fi

  #DOCKER_BUILDKIT=1 docker login ghcr.io $(cat "$HOME/github_credentials")

  #pwd

  #./oras cp --from-oci-layout ./myimage:latest ghcr.io/workinright/openpilot-base

  cd myimage
  ######ls
  "../$(dirname "$0")/basher_upload"

  #docker push ghcr.io/workinright/openpilot-base
fi

#docker run openpilot-base:latest bash

fi
