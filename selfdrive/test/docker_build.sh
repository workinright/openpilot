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

#wget -O - "https://github.com/oras-project/oras/releases/download/v1.2.3/oras_1.2.3_linux_amd64.tar.gz" \
#  | pigz -d | tar xf -

#mkdir container
#chmod +x oras
#./oras copy ghcr.io/workinright/openpilot-base:latest --to-oci-layout container
#cd container
REPO="workinright/openpilot-base"
TAG="latest"
IMAGE="ghcr.io/$REPO"
OUTPUT_DIR="container"

echo "[*] Creating OCI layout directory: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/blobs/sha256"

echo "[*] Requesting Bearer token from GHCR..."
TOKEN=$(curl -s "https://ghcr.io/token?scope=repository:$REPO:pull" | jq -r .token)

echo "[*] Fetching manifest for $IMAGE:$TAG"
MANIFEST=$(curl -s -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.v2+json" \
  "https://ghcr.io/v2/$REPO/manifests/$TAG")

# Save manifest to file
MANIFEST_FILE="$OUTPUT_DIR/manifest.json"
echo "$MANIFEST" > "$MANIFEST_FILE"

# Calculate SHA256 of the manifest
MANIFEST_DIGEST=$(sha256sum "$MANIFEST_FILE" | cut -d ' ' -f1)
cp "$MANIFEST_FILE" "$OUTPUT_DIR/blobs/sha256/$MANIFEST_DIGEST"

echo "[*] Manifest digest: sha256:$MANIFEST_DIGEST"

# Download config blob
CONFIG_DIGEST=$(echo "$MANIFEST" | jq -r .config.digest | cut -d ':' -f2)
echo "[*] Downloading config blob: sha256:$CONFIG_DIGEST"

curl -s -H "Authorization: Bearer $TOKEN" \
  "https://ghcr.io/v2/$REPO/blobs/sha256:$CONFIG_DIGEST" \
  -o "$OUTPUT_DIR/blobs/sha256/$CONFIG_DIGEST"

# Download each layer
echo "[*] Downloading layer blobs..."
LAYER_DIGESTS=$(echo "$MANIFEST" | jq -r '.layers[].digest')

declare -a pids
for DIGEST in $LAYER_DIGESTS; do
  HASH=$(echo "$DIGEST" | cut -d ':' -f2)
  echo "    ↳ sha256:$HASH"
  curl -L -s -H "Authorization: Bearer $TOKEN" \
    "https://ghcr.io/v2/$REPO/blobs/sha256:$HASH" \
    -o "$OUTPUT_DIR/blobs/sha256/$HASH" &
    pids+=($!)

done

for pid in ${pids[@]}
do
  wait $pid
done

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

echo "OCI image layout saved to '$OUTPUT_DIR'"

cd container
id="$(tar cf - * | docker import -)"
echo "$id"
docker tag $id ghcr.io/workinright/openpilot-base:latest
rm -rf container

#docker pull ghcr.io/workinright/openpilot-base:latest
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
