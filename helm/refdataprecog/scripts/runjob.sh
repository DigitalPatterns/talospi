#!/usr/bin/env bash
set +x

env

if [[ -z ${RESET} ]];
then
  if [[ ${RESET} = "true" ]];
  then
    echo "About to delete refdataprecog"

    echo "Clear reference DB"
    export REFDB_URL="postgresql://${DB_OWNERNAME}:${DB_OWNERPASSWORD}@${DB_HOSTNAME}:${DB_PORT}/${DB_NAME}${DB_OPTIONS}"
    psql ${REFDB_URL} -c "drop database if exists ${DB_REF_REFERENCE_DBNAME};"

    echo "Clear roles and schemas"
    export ROOT_URL="postgresql://${FLYWAY_PLACEHOLDERS_MASTERUSER}:${FLYWAY_PASSWORD}@${DB_HOSTNAME}:${DB_PORT}/${DB_DEFAULT_DBNAME}${DB_OPTIONS}"
    psql ${ROOT_URL} -c "drop schema ${DB_NAME} cascade; drop table if exists flyway_schema_history; drop role if exists ${REFERENCE_AUTHENTICATOR_USERNAME}; drop role if exists ${DB_OWNERNAME}; drop role if exists ${REFERENCE_ANONUSERNAME}; drop role if exists ${REFERENCE_SERVICEUSERNAME}; drop role if exists ${REFERENCE_READONLYUSERNAME};"
  fi
fi

/docker/run.sh
