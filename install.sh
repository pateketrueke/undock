#!/bin/bash

DOCKER_DIR="$HOME/.docker"
DOCKER_FILE="$DOCKER_DIR/Dockerfile"

if [[ ! -d "$DOCKER_DIR" ]]; then mkdir -p "$DOCKER_DIR"; fi
if [[ ! -f "$DOCKER_FILE" ]]; then cp "$(dirname $0)/Dockerfile" "$DOCKER_FILE"; fi
