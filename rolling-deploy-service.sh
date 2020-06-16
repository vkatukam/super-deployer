#!/bin/sh
if [[ \$(ssh docker@$APP_SERVER docker service ls | grep ${DEPLOYED_SERVICE_NAME}) ]]; then
  ssh docker@$APP_SERVER 'docker service update --force \\
    --update-order start-first \\
    --detach \\
    --health-cmd="wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1" \\
    --image nexus.se.telenor.net:5080/bapi/${ENVIRONMENT}/${SERVICE_NAME}:${VERSION}  \\
    --args "${ARGS} -Djava.net.preferIPv4Stack=true" \\
    $SECRETS_ARGS_UPDATE ${DEPLOYED_SERVICE_NAME}'
else
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
    --health-cmd='wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1' \\
    --restart-max-attempts=3 \\
    --limit-cpu 2 \\
    --limit-memory 500m \\
    --detach \\
  $SECRETS_ARGS_CREATE nexus.se.telenor.net:5080/bapi/${ENVIRONMENT}/${SERVICE_NAME}:${VERSION}   ${ARGS} -Djava.net.preferIPv4Stack=true"
fi
ssh docker@$APP_SERVER '/home/docker/network-move.sh ${DEPLOYED_SERVICE_NAME}'
echo Done with deploy-service.sh for ${DEPLOYED_SERVICE_NAME}:${VERSION} ${ARGS}
