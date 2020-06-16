#!/bin/sh
ssh docker@$APP_SERVER "docker service rm ${DEPLOYED_SERVICE_NAME}"
ssh docker@$APP_SERVER "docker service create --name ${DEPLOYED_SERVICE_NAME} \\
  --network services-2 \\
  --label "builtby"='${BUILD_USER}' \\
  --label se.telenor.service.type=services \\
  --label se.telenor.service.group=${GROUP} \\
  --container-label se.telenor.service.type=services \\
  --container-label se.telenor.service.group=${GROUP} \\
  --constraint='node.role == worker' \\
  --constraint='node.hostname != dgrfintp01.bredband.local' \\
  --constraint='node.hostname != delkintp01.bredband.local' \\
  --restart-max-attempts 3 \\
  --limit-cpu 2 \\
  --limit-memory 500m \\
  --detach \\
$SECRETS_ARGS_CREATE nexus.se.telenor.net:5080/bapi/${ENVIRONMENT}/${SERVICE_NAME}:${VERSION}  ${ARGS} -Djava.net.preferIPv4Stack=true"
ssh docker@$APP_SERVER '/home/docker/network-move.sh ${DEPLOYED_SERVICE_NAME}'
echo Done with deploy-service.sh for ${DEPLOYED_SERVICE_NAME} ${ARGS}
