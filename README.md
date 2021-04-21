#Confluent Platform AWS Sandbox

A sandbox environment to run the [Ansible Playbooks for the Confluent Platform](https://docs.confluent.io/ansible/current).
This repo provides resources built with Terraform, to which a Kafka cluster is deployed using the Ansible playbooks provided 
by Confluent. This is orchestrated with shell inside a docker contaner.


## Docker
Docker is used to ensure a consistent build environment, as well as to ensure running is easy one click, build. No install,
desides docker. The Dockerfile and accompanying scripts provide a controlled environment to both run Terraform and Ansible. 
There is a [shell script](build_env/apply.sh) within the container that will orchestrate the Terraform and ansible commands.

## How to
There is a script [docker.sh](docker.sh) that both builds the image and runs the container. This is used for interacting
with the tooling. See below for some examples...

##### Build the stack with default configurations

```shell script
./docker.sh
```

This will kick off a docker build before running the container with it's default configuration. There are some 
[environment variables](#environment-variables) that allow behaviour to be overidden.

##### Destroy the stack 

```shell script
DESTROY=1 ./docker.sh
```

Invokes just Terraform in a destroy cycle.

##### Run some custom commands

```shell script
./docker bash
```
You can override the command run within the container to run anything you like. This is pretty useful when debuggin for 
example a failed Terraform plan. To do so add the command you'd like to run as am arument to the script, or better still 
pass `bash` in, you'll get an interactive shell to explore the filesystem, debug and fix errors. For example you may 
want to list the terraform state...

```shell script
./docker bash
cd tf
terraform state list
```

It's worth pointing out that although a new container is run each time you execute a command or create an interactive shell,
any changes to the terraform source and local state file will be unaffected as the `tf` directory in this repo is mounted
as a volume. 

## Environment variables
| Variable       | Description                                               | Default   |
|----------------|-----------------------------------------------------------|-----------|
| INSTANCE_COUNT | The number of instances in the cluster                    | 3         |
| INSTANCE_TYPE  | The AWS EC2 instance type used for the cluster instances  | t3.large  |
| DESTROY        | Destroy the stack, set to 1 to do so                      | 0         |

The script also passes on the following 
[AWS environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) 
to the running process in the container...

* AWS_SECRET_ACCESS_KEY
* AWS_ACCESS_KEY_ID
* AWS_SESSION_TOKEN
* AWS_DEFAULT_REGION

as well as mounting the `~/.aws` folder into the same path in the container