FROM ruby:2.5

RUN gem install bundler

ADD Gemfile /tmp
ADD Gemfile.lock /tmp
WORKDIR /tmp
RUN bundle install

ADD . /app
WORKDIR /app

EXPOSE 9292

CMD ["bundle", "exec", "foreman", "start"]
