FROM centos:7

# Basic Package Install
RUN curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
RUN yum -y update && yum -y install \
      bzip2 gcc-c++ patch \
      epel-release \
      ruby-devel ruby \
      openssl-devel \
      readline-devel \
      sqlite-devel \ 
      ImageMagick-devel \
      postgresql \
      postgresql-server \
      postgresql-devel \
      pgbouncer \
      git \
      nodejs &&\
    yum -y install nginx


RUN useradd -G postgres,nginx kagetra
RUN chown kagetra:postgres -R /var/lib/pgsql/ /var/run/postgresql/ &&\
    chown kagetra:nginx -R /var/lib/nginx/ /var/log/nginx/ /etc/nginx/


USER kagetra
ENV HOME=/home/kagetra LANGUAGE="en_US.UTF-8"  LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8"
WORKDIR /home/kagetra

RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
ENV PATH $HOME/.rbenv/bin:$PATH
RUN echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
RUN rbenv install 2.4.0

RUN git clone --depth 1 https://github.com/pjmtdw/kagetra.git
WORKDIR /home/kagetra/kagetra

RUN rbenv local 2.4.0
RUN bash -lc "gem install bundler &&bundle install --path .vendor/bundle"
RUN npm install coffee-script@1.6.3 requirejs bower && \
    ./node_modules/bower/bin/bower install

RUN cp conf.rb.sample conf.rb && \
    sed -i -e '/^CONF_DB_USERNAME /{s/<user>/kagetra/}' conf.rb &&\
    sed -i -e '/^CONF_DB_PASSWORD /{s/<pass>/kagetra/}' conf.rb &&\
    sed -i -e '/^CONF_DB_HOST /{s/<host>/localhost/}' conf.rb &&\
    sed -i -e '/^CONF_DB_PORT /{s/port/5432/}' conf.rb &&\
    sed -i -e '/^CONF_DB_DATABASE /{s/<db>/kagetra/}' conf.rb &&\
    sed -i -e '/^CONF_DB_OSM_DATABASE /{s/"<osm_db>"/nil/}' conf.rb

RUN sed -i -e '/^add_import_path/{s/#{RUBY_VERSION}/2.4.0/}' deploy/compass_conf.rb
RUN bash -lc "cd deploy && make"

RUN initdb -D /var/lib/pgsql/data && \
    pg_ctl start -D /var/lib/pgsql/data -s -w -t 300 && \
    createdb -E UTF8 -O kagetra kagetra && \
    bash -lc "bundle exec ./scripts/initial_config.rb" && \
    bash -lc "bundle exec ./scripts/initial_config.rb -p kagetora" && \
    pg_ctl stop -D /var/lib/pgsql/data

COPY nginx.conf /etc/nginx/nginx.conf
RUN cp /home/kagetra/kagetra/deploy/nginx.site.example /etc/nginx/conf.d/kagetra.conf &&\
    sed -i -e 's!/path/to/kagetra!/home/kagetra/kagetra!' /etc/nginx/conf.d/kagetra.conf &&\
    sed -i -e 's/listen 80;/listen 1530;/' /etc/nginx/conf.d/kagetra.conf

CMD /usr/sbin/nginx &&\
    pg_ctl start -D /var/lib/pgsql/data -s -w -t 300 &&\
    bash -lc "cd scripts && ./unicorn_ctl.sh start" &&\
    while true; do sleep 1000; done

EXPOSE 1530
