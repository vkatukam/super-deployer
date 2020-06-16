#!/bin/sh
set -e

${ENTRYPOINT_SECRETS}

exec java ${JVM_ARG} -jar ${SERVICE_NAME}.jar "\$@"
