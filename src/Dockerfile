FROM php:8.0.8-cli-alpine3.14

ENV PS1='\[\033[1;32m\]🐳  \[\033[1;36m\][\u@\h] \[\033[1;34m\]\w\[\033[0;35m\] \[\033[1;36m\]# \[\033[0m\]'

ENV COMPOSER_VERSION 2.0.8
ENV PHP_XDEBUG_VERSION 3.0.2
ENV PHP_APCU_VERSION 5.1.19

ENV PHPIZE_DEPS \
    autoconf \
    cmake \
    file \
    g++ \
    gcc \
    libc-dev \
    pcre-dev \
    make \
    # php-gd
    freetype-dev \
    libpng-dev  \
    libwebp-dev \
    libjpeg-turbo-dev \
    libxslt-dev \
    # php-intl
    icu-dev

# https://github.com/nunomaduro/phpinsights/issues/43#issuecomment-498108857
# fix work iconv library with alpine
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN apk add --no-cache --virtual .persistent-deps \
    # php-gd
    freetype \
    libpng \
    libwebp \
    libjpeg-turbo \
    libxslt \
    # php-intl
    icu-libs \
    # postgres
    postgresql-dev \
    # system
    msmtp \
    util-linux \
    bash \
    vim \
    sudo \
    git

RUN set -xe \
    && apk add --no-cache --virtual .build-deps \
       $PHPIZE_DEPS \
    && docker-php-ext-configure gd \
            --enable-gd \
            --with-freetype=/usr/include/ \
            --with-jpeg=/usr/include/ \
            --with-webp=/usr/include/ \
    && docker-php-ext-configure mysqli --with-mysqli \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql \
    && docker-php-ext-configure pdo_pgsql --with-pdo-pgsql \
    && docker-php-ext-configure intl --enable-intl \
    && docker-php-ext-configure opcache --enable-opcache \
    && pecl install xdebug-${PHP_XDEBUG_VERSION} \
    && docker-php-ext-enable xdebug \
    && pecl install apcu-${PHP_APCU_VERSION} \
    && docker-php-ext-enable apcu \
    && docker-php-ext-install -j$(nproc) \
            gd \
            mysqli \
            pdo_mysql \
            pdo_pgsql \
            intl \
            opcache \
            bcmath \
    && apk del .build-deps \
    && rm -rf /tmp/* \
    && rm -f /docker-entrypoint.sh

RUN apk update \
    && apk add -U tzdata \
    && cp /usr/share/zoneinfo/Europe/Moscow /etc/localtime \
    && echo "Europe/Moscow" > /etc/timezone \
    && apk del tzdata \
    && rm -rf /var/cache/apk/*

RUN apk update \
    && apk add postgresql-client

RUN mkfifo -m 0666 /var/log/cron.log \
    && ln -s /var/log/cron.log /var/log/crond.log

RUN cp /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.original

COPY etc/msmtprc /etc/msmtprc
COPY etc/conf.d/php.ini /usr/local/etc/php/conf.d/php.ini
COPY etc/cli-entrypoint.sh /cli-entrypoint.sh

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV WORKDIR /usr/data/app

RUN set -xe \
    && mkdir -p "$COMPOSER_HOME" \
    && mkdir -p "$WORKDIR" \
    && php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');" \
    && php -r "if(hash_file('SHA384','/tmp/composer-setup.php')==='756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3'){echo 'Verified';}else{unlink('/tmp/composer-setup.php');}" \
    && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/bin --filename=composer --version=$COMPOSER_VERSION \
    && composer --ansi --version --no-interaction \
    && composer clear-cache \
    && rm -rf /tmp/composer-setup.php /tmp/.htaccess /tmp/cache \
    && php -v \
    && php -m

WORKDIR "$WORKDIR"

ENTRYPOINT ["/cli-entrypoint.sh"]

CMD ["crond", "-f", "-d", "8"]
