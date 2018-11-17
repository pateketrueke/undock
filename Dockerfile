FROM ubuntu as develop
  RUN apt-get update && apt-get install -y git curl build-essential
