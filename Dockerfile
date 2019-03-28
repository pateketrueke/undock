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
  RUN mkdir -p /app /home/dev
  RUN chown -R dev /app /home/dev
  RUN echo "dev ALL=NOPASSWD: ALL" >> /etc/sudoers

  # user, workdir, editor
  USER dev
  WORKDIR /app
  ENV EDITOR=/usr/bin/vim
