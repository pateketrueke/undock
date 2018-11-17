# Dind for idiots.

Useful single-shot command for Docker-in-Docker containers.

It will run `$HOME/.docker/Dockerfile` with some folders mounted:

- `/var/run/docker.sock`
- `$HOME/.gitconfig`
- `$HOME/.ssh`

Example:

```Dockerfile
FROM ubuntu as develop
  RUN apt-get update && apt-get install -y build-essential
```

## Usage

Install it globally with `npm i -g undock` or just use `npx`, e.g.

```bash
$ npx undock [TARGET] [PROJECT] -- [COMMAND]
```

> Installation will create a dummy `Dockerfile` if there is none already.
