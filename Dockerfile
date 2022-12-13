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

FROM --platform=linux/amd64 trafex/php-nginx

USER root
RUN apk add --no-cache php81-pdo_mysql php81-tokenizer php81-bcmath php81-ctype php81-curl php81-dom php81-fileinfo php81-json php81-mbstring php81-openssl php81-xml php81-simplexml
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
USER nobody

COPY docker/nginx.conf /etc/nginx/
COPY --chown=nobody --from=compile /sendportal /var/www/html
