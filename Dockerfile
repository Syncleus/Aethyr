FROM archlinux:base-devel

RUN pacman -Sy --noconfirm
RUN pacman -S --noconfirm ruby git base-devel glibc
RUN gem install --no-user-install bundler

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY . .
RUN rm -rf storage && rm -rf lib/aethyr/extensions/reactions

RUN bundle install
#RUN bundle update --bundler

#cleanup
RUN rm -rf .git

EXPOSE 8888
CMD ["bundle", "exec", "./bin/aethyr", "run"]
