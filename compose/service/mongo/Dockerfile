ARG MONGO_VERSION

FROM mongo:${MONGO_VERSION}

COPY ./etc/keyfile /etc/mongo/keyfile
RUN chmod 400 /etc/mongo/keyfile

EXPOSE 27017 27018 27019 28017
