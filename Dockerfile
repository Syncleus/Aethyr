FROM ruby:2.6

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

#COPY Gemfile Gemfile.lock ./
COPY . .

RUN bundle install

EXPOSE 8888
CMD ["/usr/local/bin/bundle", "exec", "/usr/src/app/bin/aethyr", "run"]
