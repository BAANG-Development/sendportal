FROM php:7.3-cli-buster as compile

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions zip pcntl pdo_mysql xml

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY ./ /sendportal/
RUN touch /sendportal/.env
RUN chmod 777 -R /sendportal
RUN rm -rf /sendportal/compile
WORKDIR /sendportal
RUN rm -rf docker
RUN rm Dockerfile
RUN rm docker-compose.yml
RUN composer install --optimize-autoloader --no-interaction --no-progress
RUN php artisan vendor:publish --provider=Sendportal\\Base\\SendportalBaseServiceProvider

FROM php:7.3-fpm-buster

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pcntl pdo_mysql xml redis


RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN apt-get update && apt-get install nginx supervisor -y
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY --from=compile /sendportal /var/www/html

CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf" ]
