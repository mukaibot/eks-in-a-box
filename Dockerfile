FROM ruby:2.5

ENV AWS_REGION ap-southeast-2
ENV AWS_DEFAULT_REGION ap-southeast-2
ENV PATH="/root/.local/bin:${PATH}"

RUN apt-get update -y && apt-get install -y python-pip && pip install awscli
RUN gem install bundler
RUN mkdir -p /app/lib
COPY Gemfile Gemfile.lock eks-in-a-box.gemspec /app/
COPY lib/eks_in_a_box.rb /app/lib/
WORKDIR /app
RUN bundle install

COPY . /app
RUN bundle check || bundle install

CMD bundle exec rake e2e_tests
