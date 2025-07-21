#!/usr/bin/env bash
###set -e
#set -x

# To build sim and docs, you can run the following to mount the scons cache to the same place as in CI:
# mkdir -p .ci_cache/scons_cache
# sudo mount --bind /tmp/scons_cache/ .ci_cache/scons_cache

SCRIPT_DIR="$(dirname "$0")"

source $SCRIPT_DIR/basher

func() {
  
#LAYER_DIGESTS=$(echo "$MANIFEST" | jq -r '.layers[].digest')

#mkdir -p docker ; sudo mount -t tmpfs tmpfs docker ; sleep 2

sudo bash -c "source $SCRIPT_DIR/basher ; CONFIG_DIGEST="$CONFIG_DIGEST" ; TOKEN="$TOKEN" ; REPO="$REPO" ; TAG="$TAG" ; IMAGE="$IMAGE" ; OUTPUT_DIR="$OUTPUT_DIR" ; basher_layers "/var/lib/docker2" "/var/lib/docker""

#i=0
#declare -a pids
#prev_sha256=;prev_chain_id=;prev_new_ids=;prev_new_ids2=;
#for DIGEST in $LAYER_DIGESTS; do
#  HASH=$(echo "$DIGEST" | cut -d ':' -f2)
#  echo "    ↳ sha256:$HASH"
  #mkfifo "$OUTPUT_DIR/blobs/sha256/$HASH"
  # (
#   assign_id "$HASH";
#   echo HASH $HASH new_id $new_id; SOURCE_DIR="container";
#   TARGET_DIR="docker";
#   sha256="$HASH";
#   basher_layer ;
   
   # ) &

    #pids+=($!)
   # ((++i))
#done

#for pid in ${pids[@]}
#do
#  echo waiting for
#  wait $pid
#done


#sudo rsync -a docker/ /var/lib/docker/
#mount
#sudo umount docker

#date

#rm -rf container

#sudo umount container

#systemctl status docker


#sudo dockerd -D -l debug --log-driver none &


#time bash -c "docker load < tar.tar"
#cd ..



#echo "OCI image layout saved to '$OUTPUT_DIR'"
}

#echo ARGS $@

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

#wget -O - "https://github.com/oras-project/oras/releases/download/v1.2.3/oras_1.2.3_linux_amd64.tar.gz" \
#  | pigz -d | tar xf -

#mkdir container
#chmod +x oras
#./oras copy ghcr.io/workinright/openpilot-base:latest --to-oci-layout container
#cd container

func

#sudo systemctl stop docker ; sleep 1 ; sudo rm -rf /var/lib/docker ; sudo mkdir /var/lib/docker ; sudo chmod 744 /var/lib/docker ; sudo mount -t tmpfs tmpfs /var/lib/docker ; sleep 1 ; sudo systemctl start docker
#docker pull ghcr.io/workinright/openpilot-base


#cd container
#tar cf ../cnt.tar *
#cd ..
#id="$(tar cf - * | docker load)"
#tar cf - * | docker load
#cd ..
#####rm -rf container
#echo "$id"
#docker tag $id ghcr.io/workinright/openpilot-base:latest
#rm -rf container

#mkfifo fifo1
#skopeo copy docker://ghcr.io/workinright/openpilot-base:latest   docker-archive:fifo1 &
#docker load < fifo1

#docker pull ghcr.io/workinright/openpilot-base:latest
#docker tag ghcr.io/workinright/openpilot-base121:latest ghcr.io/workinright/openpilot-base:latest

#docker tag 7eb1b2d52293 ghcr.io/workinright/openpilot-base:latest
#docker tag ghcr.io/workinright/openpilot-base:latest $REMOTE_SHA_TAG
#docker tag ghcr.io/workinright/openpilot-base:latest $LOCAL_TAG

#docker run --shm-size 2G -v $PWD:/tmp/openpilot -w /tmp/openpilot -e CI=1 -e PYTHONWARNINGS=error -e FILEREADER_CACHE=1 -e PYTHONPATH=/tmp/openpilot -e NUM_JOBS -e JOB_ID -e GITHUB_ACTION -e GITHUB_REF -e GITHUB_HEAD_REF -e GITHUB_SHA -e GITHUB_REPOSITORY -e GITHUB_RUN_ID -v $GITHUB_WORKSPACE/.ci_cache/scons_cache:/tmp/scons_cache -v $GITHUB_WORKSPACE/.ci_cache/comma_download_cache:/tmp/comma_download_cache -v $GITHUB_WORKSPACE/.ci_cache/openpilot_cache:/tmp/openpilot_cache $BASE_IMAGE /bin/bash -c

#journalctl -xu docker.service

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
