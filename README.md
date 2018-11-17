# Dind for idiots.

Useful single-shot command for Docker-in-Docker containers.

It will run `$HOME/.docker/Dockerfile` (or `$PWD/Dockerfile` if any) with some folders mounted:

- `/var/run/docker.sock`
- `$HOME/.gitconfig`
- `$HOME/.ssh`

Example:

```Dockerfile
FROM ubuntu as backend
  RUN apt-get update && apt-get install -y curl git sudo build-essential

# development utilities
FROM backend as nodejs
  RUN curl -sL https://deb.nodesource.com/setup_11.x | bash -
  RUN apt-get install -y nodejs httpie vim
  RUN npm i -g npm@latest

# setup environment
FROM nodejs as develop
  RUN useradd -G staff,root dev
  RUN mkdir -p /usr/src/dev /home/dev
  RUN chown -R dev /usr/src/dev /home/dev
  RUN echo "dev ALL=NOPASSWD: ALL" >> /etc/sudoers

  # user, workdir, editor
  USER dev
  WORKDIR /usr/src/dev
  ENV EDITOR=/usr/bin/vim
```

## Usage

Install it globally with `npm i -g undock` or just use `npx`, e.g.

```bash
$ npx undock [TARGET] [PROJECT] -- [COMMAND]
```

> Installation will create a dummy `Dockerfile` if there is none already.
