FROM ruby:3.4

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      zbar-tools \
      imagemagick \
      libheif-dev \
      nodejs \
      npm \
    && rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT=development:test

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY client/ ./client/
RUN cd client && npm install && npm run build

COPY . .

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
