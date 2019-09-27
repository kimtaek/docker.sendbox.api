FROM ubuntu:18.04
MAINTAINER Kimtaek <jinze1991@icloud.com>

RUN apt update \
    && DEBIAN_FRONTEND=noninteractive apt install -y locales tzdata \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8

ENV DEBCONF_NOWARNINGS yes
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV TZ=Asia/Seoul

RUN ln -fs /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata

# Install "software-properties-common" (for the "add-apt-repository")
RUN apt -y install software-properties-common

# Add the "PHP 7" ppa
RUN add-apt-repository ppa:ondrej/php \
    && add-apt-repository ppa:ondrej/nginx

# Install Mariadb
RUN echo "mysql-server mysql-server/root_password password root" | debconf-set-selections \
    && echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections \
    && apt -y install mariadb-server

# Install Redis, Nginx, Supervisor and some useful Tools
RUN apt install -y \
    nginx \
    supervisor \
    dialog \
    redis-server \
    git \
    cron \
    curl \
    vim

# Install PHP-CLI 7, some PHP extentions
RUN rm -Rf /etc/php/* && apt install -y \
    php7.2 \
    php7.2-fpm \
    php7.2-cli \
    php7.2-common \
    php7.2-bcmath \
    php7.2-mbstring \
    php7.2-soap \
    php7.2-xml \
    php7.2-zip \
    php7.2-apcu \
    php7.2-json \
    php7.2-gd \
    php7.2-curl \
    php7.2-mysql \
    php7.2-xdebug \
    php7.2-imap \
    php7.2-tidy

RUN rm -rf /etc/php/5.6 /etc/php/7.0 /etc/php/7.1 /etc/php/7.3
RUN apt clean

# Configure Supervisor, Mariadb configs
ADD startup.sh /opt/bin/startup.sh
RUN chmod u=rwx /opt/bin/startup.sh
RUN sed -e '29d' < /etc/mysql/mariadb.conf.d/50-server.cnf >> /etc/mysql/mariadb.conf.d/server.cnf
RUN rm -rf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY default.example.conf /etc/nginx/sites-available/default

# Configure Php.ini
RUN sed -ri "s/post_max_size = 8M/post_max_size = 128M/g" /etc/php/7.2/fpm/php.ini
RUN sed -ri "s/upload_max_filesize = 2M/upload_max_filesize = 32M/g" /etc/php/7.2/fpm/php.ini
RUN sed -ri "s/memory_limit = 128M/memory_limit = 256M/g" /etc/php/7.2/fpm/php.ini

# Install Composer
RUN curl -s http://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

WORKDIR /www

EXPOSE 80 443 3306 6379 9001
ENTRYPOINT ["/opt/bin/startup.sh"]