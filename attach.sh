#!/bin/bash

set -eu

ARGV="$@"
REBUILD="no"
WORKING_DIR="$PWD"

if [[ -z "$ARGV" ]] || [[ $ARGV =~ ^--help ]]; then
  echo
  echo "Usage:"
  echo "  undock [NAME] [TARGET] [PROJECT] [NETWORK] [...] [-- COMMAND]"
  echo
  echo "Examples:"
  echo "  undock test"
  echo "  undock web -p 3000,80:4000"
  echo "  undock user nodejs -- make run service=%"
  echo "  undock test -f services/test/Dockerfile -c services/test/src -- env"
  echo
  echo "Options:"
  echo "  -c, --cwd     Custom working directory  (default: $PWD)"
  echo "  -f, --file    Custom filepath for Dockerfile  (default: ~/.docker/Dockerfile)"
  echo "  -p, --ports   Expose ports from attached container"
  echo "  -b, --build   Build given Dockerfile before run"
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
[[ $ARGV =~ ^(.*)?-(-ports|p)(=| )([^ ]+) ]];

if [[ ! -z "${BASH_REMATCH[4]:-}" ]]; then
  PORTS="${BASH_REMATCH[4]}"
  ARGV="${BASH_REMATCH[1]}"
fi

# extract --file
[[ $ARGV =~ ^(.*)?-(-file|f)(=| )([^ ]+) ]];

if [[ ! -z "${BASH_REMATCH[4]:-}" ]]; then
  DOCKER_FILE="${BASH_REMATCH[4]}"
  ARGV="${BASH_REMATCH[1]}"
fi

# extract --cwd
[[ $ARGV =~ ^(.*)?-(-cwd|c)(=| )([^ ]+) ]];

if [[ ! -z "${BASH_REMATCH[4]:-}" ]]; then
  WORKING_DIR="${BASH_REMATCH[4]}"
  ARGV="${BASH_REMATCH[1]}"
fi

# extract `name target project network`
[[ $ARGV =~ ^([^ ]*)( ([^ ]*))?( ([^ ]*))?( ([^ ]*))? ]];

BUILD_NAME="${BASH_REMATCH[1]:-app}"
BUILD_TARGET="${BASH_REMATCH[3]:-develop}"
PROJECT_NAME="${BASH_REMATCH[5]:-$(basename $PWD)}"
NETWORK_NAME="${PROJECT_NAME}_${BASH_REMATCH[7]:-default}"
DOCKER_FILE="${DOCKER_FILE:-$HOME/.docker/Dockerfile}"

HISTORY="-v $HOME/.bash_history:/home/dev/.bash_history"
SOCKET="-v /var/run/docker.sock:/var/run/docker.sock"
GITCONFIG="-v $HOME/.gitconfig:/home/dev/.gitconfig"
SSHDIR="-v $HOME/.ssh:/home/dev/.ssh"
HOMEDIR="-v $WORKING_DIR:/app"
NAME="--name $BUILD_NAME"

EXPOSE="-P"
HOSTNAME="--hostname $BUILD_NAME"
PORTS=( $(echo "${PORTS:-}" | tr ',' ' ') )
CMD="$(echo $EXEC | sed 's/^--//' | sed s/%/$BUILD_NAME/g)"
ENV=""

if [[ ! -z "${PORTS:-}" ]]; then
  for PORT in "${PORTS[@]}"; do
    EXPOSE+=" -p $PORT"
  done
fi

if [[ -f "$WORKING_DIR/.env" ]]; then
  ENV="--env-file $WORKING_DIR/.env"
fi

if [[ "$REBUILD" = "yes" ]]; then
  if [[ -f "$PWD/.dockerignore" ]]; then
    cp "$PWD/.dockerignore" "$PWD/.dockerignore.bak"
  else
    touch "$PWD/.dockerignore"
  fi

  echo ".git" >> "$PWD/.dockerignore"
  echo "node_modules" >> "$PWD/.dockerignore"

  docker build --target $BUILD_TARGET -t $PROJECT_NAME -f $DOCKER_FILE $WORKING_DIR || true

  if [[ -f "$PWD/.dockerignore.bak" ]]; then
    rm "$PWD/.dockerignore"
    mv "$PWD/.dockerignore.bak" "$PWD/.dockerignore"
  else
    rm "$PWD/.dockerignore"
  fi
  exit 0
fi

if ! docker network ls | grep $NETWORK_NAME > /dev/null; then
  docker network create -d bridge $NETWORK_NAME > /dev/null
fi

if ! docker network inspect $NETWORK_NAME | grep "\"Name\": \"$BUILD_NAME\"" > /dev/null; then
  docker run -d -it --rm --privileged \
    $ENV $NAME $EXPOSE $HOSTNAME $SOCKET $GITCONFIG \
    $SSHDIR $HOMEDIR $HISTORY $PROJECT_NAME $CMD > /dev/null
  docker network connect $NETWORK_NAME $BUILD_NAME
  docker attach $BUILD_NAME
else
  docker network disconnect $NETWORK_NAME $BUILD_NAME
  docker stop $BUILD_NAME
fi
