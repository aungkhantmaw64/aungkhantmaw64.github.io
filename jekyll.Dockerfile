FROM jekyll/jekyll

COPY . /home/jekyll

WORKDIR /home/jekyll

RUN bundle

