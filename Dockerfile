FROM ruby:2.5

RUN apt-get update -y && apt-get install -y awscli
ENV AWS_REGION ap-southeast-2
RUN mkdir /app
WORKDIR /app

COPY . /app
RUN bundle install

CMD bundle exec rake
