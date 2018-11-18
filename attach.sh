#!/bin/bash

# extract `-- command`
[[ $@ =~ ^(.* )?(-- )(.+)$ ]];

ARGV="${BASH_REMATCH[1]}"
EXEC="${BASH_REMATCH[3]:-/bin/bash}"

if [[ -z "$ARGV" ]] && [[ "${BASH_REMATCH[2]}" != "-- " ]]; then
  ARGV="$@"
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

docker build --target $BUILD_TARGET -t $PROJECT_NAME -f $DOCKER_FILE .
docker run -it --privileged $SOCKET $GITCONFIG $SSHDIR $HOMEDIR $PROJECT_NAME $EXEC
