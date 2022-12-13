FROM --platform=linux/amd64 php:7.3-cli-buster as compile

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions zip pcntl pdo_mysql xml

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY ./ /sendportal/
RUN touch /sendportal/.env
RUN chmod 777 -R /sendportal
WORKDIR /sendportal
RUN rm -rf docker
RUN rm Dockerfile
RUN composer install --optimize-autoloader --no-interaction --no-progress
RUN php artisan vendor:publish --provider=Sendportal\\Base\\SendportalBaseServiceProvider

FROM --platform=linux/amd64 ghcr.io/nostrathomas99/nginx-le:master as nginx

RUN apk add --no-cache php php-fpm php-ctype php-curl php-dom php-gd php-intl php-mbstring php-mysqli php-opcache php-openssl php-phar php-session php-xml php-xmlreader php-pdo_mysql php-tokenizer php-bcmath php-ctype php-curl php-dom php-fileinfo php-json php-mbstring php-openssl php-xml php-simplexml

COPY docker/fpm-pool.conf /etc/php/php-fpm.d/www.conf
COPY docker/php.ini /etc/php/conf.d/custom.ini

COPY docker/laravel.conf /etc/nginx/service.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY --from=compile /sendportal /var/www/html