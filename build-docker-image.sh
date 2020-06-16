#!/bin/sh

echo "About to new build Docker image for ${SERVICE_NAME}"
echo Docker repo is nexus.se.telenor.net
echo Docker image name is bapi/${ENVIRONMENT}/${SERVICE_NAME}
docker build --tag nexus.se.telenor.net:${DOCKER_REGISTRY_PORT}/bapi/${ENVIRONMENT}/${SERVICE_NAME}:${VERSION} .
docker push nexus.se.telenor.net:${DOCKER_REGISTRY_PORT}/bapi/${ENVIRONMENT}/${SERVICE_NAME}:${VERSION}
