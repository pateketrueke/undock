#!/bin/bash

set -eu

ARGV="$@"
REBUILD="no"

if [[ -z "$ARGV" ]] || [[ $ARGV =~ ^--help ]]; then
  echo
  echo "Usage:"
  echo "  undock [NAME] [TARGET] [OPTIONS] [-- COMMAND]"
  echo
  echo "Examples:"
  echo "  undock test"
  echo "  undock web -p 3000,80:4000"
  echo "  undock user nodejs -- make run service=%"
  echo
  echo "Options:"
  echo "  -p, --ports   Expose ports from attached container"
  echo "  -b, --build   Build ~/.docker/Dockerfile before run"
  echo
  echo "The % placeholder is replaced with the given service-name."
  exit 1
fi

# extract --build
[[ $ARGV =~ ^(.*)?-(-build|b)( .+)?$ ]];

if [[ ! -z ${BASH_REMATCH[2]:-} ]]; then
  ARGV="${BASH_REMATCH[1]:-}${BASH_REMATCH[3]:-}"
  REBUILD="yes"
fi

# extract `-- command`
[[ $ARGV =~ ^(.*)( -- .+)$ ]];

EXEC=/bin/bash

if [[ ! -z "${BASH_REMATCH:-}" ]]; then
  ARGV="${BASH_REMATCH[1]:-}"
  EXEC="${BASH_REMATCH[2]:-/bin/bash}"
fi

# extract --ports
[[ $ARGV =~ ^(.*)?-(-ports|p)(=| )(.+)$ ]];

if [[ ! -z "${BASH_REMATCH[4]:-}" ]]; then
  PORTS="${BASH_REMATCH[4]:-}"
  ARGV="${BASH_REMATCH[1]:-}"
fi

# extract `target project`
[[ $ARGV =~ ^([^ ]*)( (.*))?$ ]];

BUILD_NAME="${BASH_REMATCH[1]:-app}"
BUILD_TARGET="${BASH_REMATCH[2]:-develop}"
PROJECT_NAME="${BASH_REMATCH[3]:-$(basename $PWD)}"
NETWORK_NAME="${PROJECT_NAME}_undock"
DOCKER_FILE="$HOME/.docker/Dockerfile"

SOCKET="-v /var/run/docker.sock:/var/run/docker.sock"
GITCONFIG="-v $HOME/.gitconfig:/home/dev/.gitconfig"
SSHDIR="-v $HOME/.ssh:/home/dev/.ssh"
HOMEDIR="-v $PWD:/usr/src/dev"
NAME="--name $BUILD_NAME"

EXPOSE="-P"
PORTS=( $(echo "${PORTS:-}" | tr ',' ' ') )
CMD="$(echo $EXEC | sed 's/^--//' | sed s/%/$BUILD_NAME/g)"

if [[ ! -z "${PORTS:-}" ]]; then
  for PORT in "${PORTS[@]}"; do
    EXPOSE+=" -p $PORT"
  done
fi

if [[ "$REBUILD" = "yes" ]]; then
  docker build --target $BUILD_TARGET -t $PROJECT_NAME -f $DOCKER_FILE $PWD
fi

if ! docker network ls | grep $NETWORK_NAME > /dev/null; then
  docker network create -d bridge $NETWORK_NAME
fi

if ! docker network inspect $NETWORK_NAME | grep "\"Name\": \"$BUILD_NAME\"" > /dev/null; then
  uuid=$(docker run -d -it --rm --privileged $NAME $EXPOSE $SOCKET $GITCONFIG $SSHDIR $HOMEDIR $PROJECT_NAME $CMD)

  docker network connect $NETWORK_NAME $BUILD_NAME
  docker attach $BUILD_NAME
else
  docker network disconnect $NETWORK_NAME $BUILD_NAME
  docker stop $BUILD_NAME
fi
