FROM ${BASE_IMAGE}

ADD entrypoint.sh /usr/local/
ADD ${SERVICE_NAME}.jar /usr/local/

WORKDIR /usr/local/
${JVM_INSTALL_WGET}
RUN chmod +x /usr/local/entrypoint.sh

ENTRYPOINT ["sh", "entrypoint.sh"]
