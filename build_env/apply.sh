#!/usr/bin/env bash

set -e

DESTROY=${DESTROY:-0}
if [[ "${DESTROY}" == "1" ]]; then tf_cmd="destroy"; else tf_cmd="apply"; fi
if [[ -n $INSTANCE_COUNT ]]; then tf_flags="-var=instance_count=${INSTANCE_COUNT}"; fi
if [[ -n $INSTANCE_TYPE ]]; then tf_flags="${tf_flags} -var=instance_type=${INSTANCE_TYPE}"; fi

(
  cd tf
  terraform init
  terraform $tf_cmd $tf_flags -auto-approve
  if [[ "${tf_cmd}" == "apply" ]]; then
    terraform output -raw hosts > hosts.yml
    dns=`terraform output -raw dns`
    echo "testing ssh connectivity before launching ansible"
    timeout 5m bash -c "until nc -w 5 -vz $dns 22; do echo waiting 5 seconds before ssh again && sleep 5; done"
  fi
)

if [[ "${tf_cmd}" == "destroy" ]]; then exit 0; fi

(
  cd ansible
  cmd='ansible-playbook -i /workspace/tf/hosts.yml all.yml'
  $cmd --tags=zookeeper
  $cmd --tags=kafka_broker
  $cmd --tags=schema_registry
  $cmd --tags=kafka_rest
  $cmd --tags=kafka_connect
  $cmd --tags=ksql
  $cmd --tags=control_center
)
