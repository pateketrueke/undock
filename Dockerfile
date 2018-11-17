FROM ubuntu as develop
  RUN apt-get update && apt-get install -y build-essential
