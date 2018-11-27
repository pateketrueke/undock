# Dind for the lulz.

Useful single-shot command for Docker-in-Docker containers.

It will run `$HOME/.docker/Dockerfile` with some folders mounted:

- `/var/run/docker.sock`
- `$HOME/.gitconfig`
- `$HOME/.ssh`

See included [Dockerfile](Dockerfile) as starting-point for your own setup.

Also you can check the published [Dockerfile I'm using at Docker hub](https://hub.docker.com/r/pateketrueke/undock/).

## Usage

Install it globally with `npm i -g undock` or just use `npx`, e.g.

```
$ undock [NAME] [TARGET] [PROJECT] [NETWORK] [...] [-- COMMAND]
```

## Options

- `-b, --build` &mdash; Force image build before attaching
- `-p, --ports` &mdash; Exposed ports from the attached container
- `NAME` &mdash; Container name for the mounted image (default: none)
- `TARGET` &mdash; Build target from the Dockerfile (default: `develop`)
- `PROJECT` &mdash; Project name for the built image (default: `basename $PWD`)
- `NETWORK` &mdash; Networking group used for linking containers (default: `default`)
- `-- COMMAND` &mdash; Additional command to execute (default: `/bin/bash`)

## Networking

Undock will setup the network for you based on given arguments.

However, if you can't see other containers remember connect them, e.g.

```bash
# start two containers in separated shells
$ undock web -p 80:4000 -- npm start
$ undock user -- npm start

# create a shared network and connect containers
$ docker network create -d bridge undock
$ docker network connect undock web
$ docker network connect undock user
```
