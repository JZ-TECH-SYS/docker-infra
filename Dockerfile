FROM php:8.1-apache

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Configurar e instalar extensões PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        mysqli \
        gd \
        soap \
        zip \
        mbstring \
        opcache

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Habilitar módulos úteis do Apache
RUN a2enmod rewrite headers expires

# DocumentRoot parametrizável para reutilizar esta imagem como base de várias APIs
ARG APP_DOCROOT=/var/www/html/public
ENV APACHE_DOCUMENT_ROOT=${APP_DOCROOT}
# Atualiza vhosts e configs para novo DocumentRoot
RUN sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf \
    && sed -ri -e "s!/var/www/!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Regras comuns: DirectoryIndex, AllowOverride e cache estático
RUN set -eux; \
    printf "<Directory ${APACHE_DOCUMENT_ROOT}>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
    DirectoryIndex index.php index.html\n\
    <IfModule mod_expires.c>\n\
        ExpiresActive On\n\
        ExpiresByType image/webp \"access plus 1y\"\n\
        ExpiresByType image/png \"access plus 1y\"\n\
        ExpiresByType image/jpeg \"access plus 1y\"\n\
        ExpiresByType text/css \"access plus 7d\"\n\
        ExpiresByType application/javascript \"access plus 7d\"\n\
    </IfModule>\n" > /etc/apache2/conf-available/zz-app.conf \
    && a2enconf zz-app

# Configurar permissões padrão (podem ser sobrescritas via volume)
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
    && echo "opcache.revalidate_freq=2" >> /usr/local/etc/php/conf.d/opcache.ini

WORKDIR /var/www/html

EXPOSE 80
