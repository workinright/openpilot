#!/usr/bin/env bash
###set -e
#set -x

# To build sim and docs, you can run the following to mount the scons cache to the same place as in CI:
# mkdir -p .ci_cache/scons_cache
# sudo mount --bind /tmp/scons_cache/ .ci_cache/scons_cache

func() {
  REPO="workinright/openpilot-base"
TAG="latest"
IMAGE="ghcr.io/$REPO"
OUTPUT_DIR="container"

echo "[*] Creating OCI layout directory: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/blobs/sha256"

echo "[*] Requesting Bearer token from GHCR..."
TOKEN=$(curl -L -s "https://ghcr.io/token?scope=repository:$REPO:pull" | jq -r .token)

echo "[*] Fetching manifest for $IMAGE:$TAG"
MANIFEST=$(curl -L -s -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.v2+json" \
  "https://ghcr.io/v2/$REPO/manifests/$TAG")

# Save manifest to file
MANIFEST_FILE="$OUTPUT_DIR/manifest.json"
#echo "$MANIFEST" > "$MANIFEST_FILE"
echo '[{"Config":"blobs/sha256/7eb1b2d522931ebf0b08ab1eb9877dd8a18d7c074e63377f5aa7d8deaeb8804a","RepoTags":["ghcr.io/workinright/openpilot-base:latest"],"Layers":["blobs/sha256/107cbdaeec042e6154640c94972c638f4e2fee795902b149e8ce9acbd03d59d7","blobs/sha256/217fab191c7c42284a939d32f1bab746921065cfd7f3fa1674e684a227974d8d","blobs/sha256/c03653e5cf5402c8ee1dd925ea7a5972ec57ca22ff5a4a5f4ba394b00e164c42","blobs/sha256/a59bbb8a8d17760fa86eb0784b64715e95c659e0f4475d9ecbd5def390766c4a","blobs/sha256/c816f3bba8b8f27500566fda3ab26401efb9e78301741df45a589eea1a28d328","blobs/sha256/22ed7fbdb74871ed4101fc509dd5523bd3f57f8b307e71964d8ed95e48ed8e5f","blobs/sha256/53d8ca3de39bc19aa653c7e56319e3b92980ba5e066288e11e33ef7dd9e709e3"]}]' > "$MANIFEST_FILE"

# Calculate SHA256 of the manifest
MANIFEST_DIGEST=$(sha256sum "$MANIFEST_FILE" | cut -d ' ' -f1)
cp "$MANIFEST_FILE" "$OUTPUT_DIR/blobs/sha256/$MANIFEST_DIGEST"

echo "[*] Manifest digest: sha256:$MANIFEST_DIGEST"

# Download config blob
CONFIG_DIGEST=$(echo "$MANIFEST" | jq -r .config.digest | cut -d ':' -f2)
echo "[*] Downloading config blob: sha256:$CONFIG_DIGEST"

curl -L -s -H "Authorization: Bearer $TOKEN" \
  "https://ghcr.io/v2/$REPO/blobs/sha256:$CONFIG_DIGEST" \
  -o "$OUTPUT_DIR/blobs/sha256/$CONFIG_DIGEST"

# Write oci-layout file
echo '[*] Writing oci-layout'
echo '{"imageLayoutVersion": "1.0.0"}' > "$OUTPUT_DIR/oci-layout"

# Create index.json
MEDIA_TYPE=$(echo "$MANIFEST" | jq -r .mediaType)
MANIFEST_SIZE=$(wc -c < "$MANIFEST_FILE")

echo '[*] Writing index.json'
cat > "$OUTPUT_DIR/index.json" <<EOF
{
  "schemaVersion": 2,
  "manifests": [
    {
      "mediaType": "$MEDIA_TYPE",
      "digest": "sha256:$MANIFEST_DIGEST",
      "size": $MANIFEST_SIZE,
      "annotations": {
        "org.opencontainers.image.ref.name": "$TAG"
      }
    }
  ]
}
EOF
#{"schemaVersion":2,"mediaType":"application/vnd.oci.image.index.v1+json","manifests":[{"mediaType":"application/vnd.docker.distribution.manifest.v2+json","digest":"sha256:1b9c39f2dae6a40313c408e70160efb611f8cd5ec0e3b95c15f8b6cf79031374","size":1654,"annotations":{"io.containerd.image.name":"ghcr.io/workinright/openpilot-base:latest","org.opencontainers.image.created":"2025-07-18T04:48:02Z","org.opencontainers.image.ref.name":"latest"},"platform":{"architecture":"amd64","os":"linux"}}]}

cd container
tar cf ../tar.tar *
touch tar.tar.lock
cd ..

# Download each layer
echo "[*] Downloading layer blobs..."
LAYER_DIGESTS=$(echo "$MANIFEST" | jq -r '.layers[].digest')

declare -a pids
for DIGEST in $LAYER_DIGESTS; do
  HASH=$(echo "$DIGEST" | cut -d ':' -f2)
  echo "    ↳ sha256:$HASH"
  #mkfifo "$OUTPUT_DIR/blobs/sha256/$HASH"
  ( curl -L -s -H "Authorization: Bearer $TOKEN" \
    "https://ghcr.io/v2/$REPO/blobs/sha256:$HASH" \
    -o "$OUTPUT_DIR/blobs/sha256/$HASH" ; cd container ; exec 200>tar.tar.lock ; while ! flock -n 200; do sleep 0.1; echo attempt lock; done; tar rf ../tar.tar blobs/sha256/$HASH ; exec 200>&- ; rm blobs/sha256/$HASH ) &
    pids+=($!)

done

for pid in ${pids[@]}
do
  echo waiting for
  wait $pid
done

time bash -c "sudo ctr images import - < tar.tar"
cd ..



echo "OCI image layout saved to '$OUTPUT_DIR'"
}

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

#wget -O - "https://github.com/oras-project/oras/releases/download/v1.2.3/oras_1.2.3_linux_amd64.tar.gz" \
#  | pigz -d | tar xf -

#mkdir container
#chmod +x oras
#./oras copy ghcr.io/workinright/openpilot-base:latest --to-oci-layout container
#cd container

#func

skopeo copy docker://ghcr.io/workinright/openpilot-base:latest docker-daemon:openpilot-base:latest

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
docker tag ghcr.io/workinright/openpilot-base:latest $REMOTE_SHA_TAG
docker tag ghcr.io/workinright/openpilot-base:latest $LOCAL_TAG

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
