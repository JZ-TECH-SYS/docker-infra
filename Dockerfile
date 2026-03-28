FROM php:8.1-fpm

# Instalar dependências do sistema e Nginx
RUN apt-get update && apt-get install -y \
    nginx \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    supervisor \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Configurar e instalar extensões PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mysqli \
    gd \
    soap \
    zip \
    mbstring \
    opcache \
    bcmath

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Limpar o Nginx Default e criar o nosso
COPY ./nginx/default.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Tunar PHP-FPM Pool com as configs dinâmicas
COPY ./nginx/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf

# DocumentRoot parametrizável para reutilizar esta imagem como base de várias APIs
ARG APP_DOCROOT=/var/www/html/public
ENV APACHE_DOCUMENT_ROOT=${APP_DOCROOT}

# Fix permissions
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Configurar PHP (tuning básico e timezone)
RUN echo "upload_max_filesize = 100M" > /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "date.timezone = America/Sao_Paulo" > /usr/local/etc/php/conf.d/timezone.ini \
    && echo "opcache.enable=1" > /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=2" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.jit=1255" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.jit_buffer_size=64M" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "realpath_cache_size=4096K" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "realpath_cache_ttl=600" >> /usr/local/etc/php/conf.d/opcache.ini

# Em vez do apache-foreground, usamos um script de startup para fpm + nginx
RUN echo '#!/bin/sh' > /usr/local/bin/entrypoint.sh \
    && echo 'sed -i "s|root /var/www/html/public;|root ${APACHE_DOCUMENT_ROOT};|g" /etc/nginx/sites-available/default' >> /usr/local/bin/entrypoint.sh \
    && echo 'php-fpm -D' >> /usr/local/bin/entrypoint.sh \
    && echo 'nginx -g "daemon off;"' >> /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

EXPOSE 80

CMD ["/usr/local/bin/entrypoint.sh"]
