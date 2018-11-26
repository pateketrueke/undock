#!/bin/bash

set -eu

ARGV="$@"
REBUILD="no"

# extract --build
[[ $ARGV =~ ^(.*)?-(-build|b)( .+)?$ ]];

if [[ ! -z ${BASH_REMATCH[2]:-} ]]; then
  ARGV="${BASH_REMATCH[1]:-}${BASH_REMATCH[3]:-}"
  REBUILD="yes"
fi

# extract `-- command`
[[ $ARGV =~ ^(.* )?(-- )(.+)$ ]];

ARGV="${BASH_REMATCH[1]:-}"
EXEC="${BASH_REMATCH[3]:-/bin/bash}"

if [[ -z "$ARGV" ]] && [[ "${BASH_REMATCH[2]:-}" != '-- ' ]]; then
  ARGV="$@"
fi

# extract --ports
[[ $ARGV =~ ^(.*)?-(-ports|p)(=| )(.+)$ ]];

if [[ ! -z "${BASH_REMATCH[4]:-}" ]]; then
  PORTS="${BASH_REMATCH[4]:-}"
  ARGV="${BASH_REMATCH[1]:-}"
fi

# extract `target project`
[[ $ARGV =~ ^([^ ]*)( (.*))?$ ]];

BUILD_TARGET="${BASH_REMATCH[1]:-develop}"
PROJECT_NAME="${BASH_REMATCH[3]:-$(basename $PWD)}"

DOCKER_FILE="$HOME/.docker/Dockerfile"

SOCKET="-v /var/run/docker.sock:/var/run/docker.sock"
GITCONFIG="-v $HOME/.gitconfig:/home/dev/.gitconfig"
SSHDIR="-v $HOME/.ssh:/home/dev/.ssh"
HOMEDIR="-v $PWD:/usr/src/dev"

EXPOSE=""
PORTS=( $(echo "${PORTS:-}" | tr ',' ' ') )

if [[ ! -z "${PORTS:-}" ]]; then
  for PORT in "${PORTS[@]}"; do
    EXPOSE+="-p $PORT "
  done
fi

if [[ "$REBUILD" = "yes" ]]; then
  docker build --target $BUILD_TARGET -t $PROJECT_NAME -f $DOCKER_FILE $PWD
fi

docker run -it --rm --privileged $EXPOSE $SOCKET $GITCONFIG $SSHDIR $HOMEDIR $PROJECT_NAME $EXEC
