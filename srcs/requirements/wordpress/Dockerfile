FROM alpine:3.23

ARG PHP_VERSION=85
# ARG DB_NAME
# ARG DB_USER

RUN apk update && apk upgrade && apk add --no-cache \
    php${PHP_VERSION} \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-mysqli \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-exif \
    php${PHP_VERSION}-fileinfo \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-openssl \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    wget \
    unzip
# RUN wget -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
#     chmod +x /usr/local/bin/wp
RUN sed -i "s|listen = 127.0.0.1:9000|listen = 9000|g" \
    /etc/php${PHP_VERSION}/php-fpm.d/www.conf && \
    sed -i "s|;listen.owner = nobody|listen.owner = nobody|g" \
    /etc/php${PHP_VERSION}/php-fpm.d/www.conf && \
    sed -i "s|;listen.group = nobody|listen.group = nobody|g" \
    /etc/php${PHP_VERSION}/php-fpm.d/www.conf && \
    rm -f /var/cache/apk/*

WORKDIR /var/www

RUN wget https://wordpress.org/latest.zip && \
    unzip latest.zip && \
    cp -rf wordpress/* . && \
    rm -rf wordpress latest.zip

COPY ./requirements/wordpress/conf/wp-config-create.sh /usr/local/bin/wp-config-create.sh
COPY ./requirements/wordpress/tools/wp.sh /usr/local/bin/wp.sh

RUN chmod +x /usr/local/bin/wp-config-create.sh /usr/local/bin/wp.sh && \
    chmod -R 0777 wp-content/
EXPOSE 9000
CMD ["/usr/local/bin/wp.sh"]
