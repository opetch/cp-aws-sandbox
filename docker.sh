#!/usr/bin/env bash

set -e

(
  cd build_env
  docker build . -t confluent-provisioner
)

docker run --rm -it \
  --env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
  --env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
  --env AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
  --env AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
  --env INSTANCE_COUNT=${INSTANCE_COUNT} \
  --env INSTANCE_TYPE=${INSTANCE_TYPE} \
  --env DESTROY=${DESTROY} \
  -v "${PWD}/tf":"/workspace/tf/" \
  -v "${HOME}/.aws/":"/root/.aws/" \
  confluent-provisioner "${@}"
