FROM php:8.1-fpm-alpine

ARG SATIS_VERSION=3.5.1

ENV USER_HOME=/home/www
ENV USER=www
ENV TZ=Europe/Amsterdam
ENV CRON_PATH=/var/spool/cron/crontabs

# Install nginx and other dependencies
RUN apk update && apk add --no-cache \
    supervisor \
    nginx \
    tzdata \
    libxml2-dev \
    busybox \
    bash \
    openssh-client \
    git \ 
    sudo

# Install PHP extensions
RUN docker-php-ext-install xml

# Configure Nginx
RUN adduser -D -g ${USER} ${USER}
RUN mkdir -p /etc/nginx/http.d \
    && rm -f /etc/nginx/http.d/default.conf
COPY ./nginx/nginx.conf /etc/nginx/http.d/satis.conf

# Create .ssh directory for keys
RUN mkdir -p ${USER_HOME}/.ssh

# Cron
RUN echo "" > /${CRON_PATH}/root

# Scripts
COPY ./scripts /app/scripts

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install satisfy https://github.com/project-satisfy/satisfy/
RUN composer create-project playbloom/satisfy:${SATIS_VERSION} /satisfy
RUN cd /satisfy \
    && composer install --no-dev -n --optimize-autoloader
COPY ./config/parameters.yml.dist /satisfy/config/parameters.yml
COPY ./config/satis.json.dist /satisfy/satis.json
RUN chown -R www:www /satisfy

# Copy the Supervisor configuration file from the host into the container
COPY ./supervisor/supervisord.conf /etc/supervisord.conf

EXPOSE 80

WORKDIR /app

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]