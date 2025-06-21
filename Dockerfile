FROM archlinux:base

LABEL maintainer="Jeffrey Phillips Freeman the@jeffreyfreeman.me"

ENV USER_HOME=/home/aethyr
ENV GEM_HOME=${USER_HOME}/.local
ENV BUNDLE_PATH=${GEM_HOME}
ENV BUNDLE_BIN=${GEM_HOME}/bin
ENV PATH=${GEM_HOME}/share/gem/ruby/3.4.0/bin:$PATH
ENV APP_DIR=/app

ARG AETHYR_UID=1000
ARG AETHYR_GID=100

#Override these as env so they can be inherited down to child containers
ENV AETHYR_UID=$AETHYR_UID
ENV AETHYR_GID=$AETHYR_GID


RUN pacman -Sy --noconfirm \
        ruby \
        ruby-erb \
        git \
        base-devel \
        gdal \
        nodejs \
        npm \
        sudo \
        net-tools \
        glibc &&\
    pacman -Scc --noconfirm

COPY . /app
COPY .docker/50-aethyr /etc/sudoers.d/50-aethyr

RUN mkdir -p $APP_DIR &&\
    groupadd --system --gid "$AETHYR_GID" aethyr &&\
    useradd  --system --uid "$AETHYR_UID" \
                --gid  "$AETHYR_GID" \
                --create-home \
                --home-dir "$USER_HOME" \
                --shell /usr/bin/bash \
                aethyr &&\
    chown -R aethyr:aethyr "$USER_HOME" "$APP_DIR"

WORKDIR $APP_DIR
USER aethyr:aethyr

RUN gem install --no-document bundler -v '~> 2.6' &&\
    git clean -xdf &&\
    rm -rf ./.bundle &&\
    bundle config build.ncursesw --with-cflags="-Wno-error=incompatible-pointer-types" &&\
    #bundle config set --local frozen true &&\
    bundle install  --jobs 4 --retry 3 &&\
    rm -rf .git


VOLUME $APP_DIR

EXPOSE 8888

CMD ["bundle", "exec", "./bin/aethyr", "run"]
