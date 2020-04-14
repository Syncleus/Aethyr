FROM archlinux/base

RUN pacman -Sy --noconfirm
RUN pacman -S --noconfirm ruby git
RUN gem install bundler

# throw errors if Gemfile has been modified since Gemfile.lock
RUN /root/.gem/ruby/2.7.0/bin/bundle config --global frozen 1

WORKDIR /usr/src/app

COPY . .
RUN rm -rf storage && rm -rf lib/aethyr/extensions/reactions

RUN /root/.gem/ruby/2.7.0/bin/bundle install
#RUN bundle update --bundler

#cleanup
RUN rm -rf .git

EXPOSE 8888
CMD ["/root/.gem/ruby/2.7.0/bin/bundle", "exec", "./bin/aethyr", "run"]
