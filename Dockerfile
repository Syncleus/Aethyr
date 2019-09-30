FROM ruby:2.6

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1
RUN gem install bundler

WORKDIR /usr/src/app

COPY . .
RUN rm -rf storage && rm -rf lib/aethyr/extensions/reactions

RUN bundle install
#RUN bundle update --bundler

#cleanup
RUN rm -rf .git

EXPOSE 8888
CMD ["bundle", "exec", "./bin/aethyr", "run"]
