# Dockerfile for development environment

FROM centos:7

RUN /bin/cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime &&\
    localedef -f UTF-8 -i ja_JP /usr/lib/locale/ja_JP.UTF-8

# Basic Package Install
# ruby build: make, bzip2, gcc-c++, make, openssl-devel, readline-devel
# nokogiri(gem): patch, sqlite-devel
RUN curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
RUN yum -y update && yum -y install \
      bzip2 gcc-c++ make patch \
      epel-release \
      ruby-devel ruby \
      openssl-devel \
      readline-devel \
      sqlite-devel \
      ImageMagick-devel \
      postgresql \
      postgresql-server \
      postgresql-devel \
      git \
      which \
      nodejs

RUN useradd -G postgres kagetra
RUN chown kagetra:postgres -R /var/lib/pgsql/ /var/run/postgresql/

USER kagetra
RUN initdb -E UTF8 --locale=ja_JP.UTF-8 -D /var/lib/pgsql/data &&\
    pg_ctl start -D /var/lib/pgsql/data -s -w -t 300 &&\
    createdb kagetra

WORKDIR /home/kagetra

RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
RUN echo -e 'PATH=~/.rbenv/bin:$PATH\neval "$(rbenv init -)"' >> ~/.bashrc
RUN ~/.rbenv/bin/rbenv install 2.5.3

EXPOSE 1530

##### After run
#   $ cd ~/kagetra
#   $ rbenv local 2.5.3
#   $ gem install bundler
#   $ bundle install --path .vendor/bundle
#   $ bundle exec rackup -o 0.0.0.0 --port 1530

## Database
#   (初期化する場合)
#   $ bundle exec ./scripts/initial_config.rb"

#   (dumpからrestoreする場合)
#   $ pg_restore -O -U kagetra -d kagetra /path/to/dump

## js
#   (jsやvueを編集する場合はホストとコンテナのうち編集する方で以下を行う)
#   $ npm install
#   $ npm run dev
