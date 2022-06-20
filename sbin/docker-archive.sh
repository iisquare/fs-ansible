#!/bin/bash

IMAGE_NAME=""
IMAGE_VERSION="latest"
TARGET_USER="root"
TARGET_HOST=""

while [ -n "$1" ]
do
  case "$1" in
    -i|--image) IMAGE_NAME=$2; shift 2;;
    -v|--image-version) IMAGE_VERSION=$2; shift 2;;
    -u|--user) TARGET_USER=$2; shift 2;;
    -h|--host) TARGET_HOST=$2; shift 2;;
    --) break ;;
    *) echo $1,$2 break ;;
  esac
done

echo "archive ${IMAGE_NAME}:${IMAGE_VERSION} to ${TARGET_USER}@${TARGET_HOST}"


IMAGE_ID=`sudo docker images|grep ${IMAGE_NAME}|grep ${IMAGE_VERSION}|awk '{print $3}'`
if [ -z "$IMAGE_ID" ]; then
  echo "image id is empty"
  exit 0
else
  echo "image id is ${IMAGE_ID}"
fi

sudo docker save -o ${IMAGE_ID}.tar ${IMAGE_ID}
tar -czvf ${IMAGE_ID}.tar.gz ${IMAGE_ID}.tar

HOSTS=(${TARGET_HOST//,/ })
for HOST in ${HOSTS[@]}
do
   echo "sync to ${HOST}..."
   scp "${IMAGE_ID}.tar.gz" ${TARGET_USER}@${HOST}:/tmp/
   ssh ${TARGET_USER}@${HOST} "tar -xzvf /tmp/${IMAGE_ID}.tar.gz -C /tmp/"
   ssh ${TARGET_USER}@${HOST} "docker load < /tmp/${IMAGE_ID}.tar"
   ssh ${TARGET_USER}@${HOST} "docker tag ${IMAGE_ID} ${IMAGE_NAME}:${IMAGE_VERSION}"
   ssh ${TARGET_USER}@${HOST} "rm -f /tmp/${IMAGE_ID}.tar /tmp/${IMAGE_ID}.tar.gz"
done

rm -f ${IMAGE_ID}.tar ${IMAGE_ID}.tar.gz
