#!/usr/bin/env bash

# set variables
IMAGE="${1}"
DEST="${2}"

# make sure IMAGE is populated
if [ -z "${IMAGE}" ]
then
  echo "ERROR: first parameter must be the image to mirror"
  exit 1
fi

# make sure DEST is populated
if [ -z "${DEST}" ]
then
  echo "ERROR: second parameter must be the destination Docker Hub namespace"
  exit 1
fi

# get manifest data from source
JSON_DATA="$(docker buildx imagetools inspect --raw "${IMAGE}")"

# make sure JSON_DATA is populated
if [ -z "${JSON_DATA}" ]
then
  echo "ERROR: JSON_DATA was not populated!"
  exit 1
fi

# get image digests from the manifest data
AMD64="$(echo "${JSON_DATA}" | jq -r '.manifests|.[]| select((.platform.architecture == "amd64") and (.platform.os == "linux"))|.digest')"
ARM64="$(echo "${JSON_DATA}" | jq -r '.manifests|.[]| select((.platform.architecture == "arm64") and (.platform.os == "linux"))|.digest')"

# make sure AMD64 and ARM64 are populated
if [ -z "${AMD64}" ] || [ -z "${ARM64}" ]
then
  echo "ERROR: either AMD64 or ARM64 was not populated!"
  exit 1
else
  # write manifest/mirror data to destination
  docker buildx imagetools create --progress plain -t "${DEST}/$(echo "${IMAGE}" | awk -F '/' '{print $NF}')" "${IMAGE}@${AMD64}" "${IMAGE}@${ARM64}"
fi
