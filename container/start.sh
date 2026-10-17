#!/bin/sh
set -eu
php /opt/hefesto/configure.php
mkdir -p /var/www/html/storage/logs /var/www/html/storage/cache /var/www/html/storage/sessions
chown -R www-data:www-data /var/www/html/storage
exec apache2-foreground
