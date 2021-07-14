#!/usr/bin/env sh
set -e

PHP_CLI_IS_DEV_ENV="${PHP_CLI_IS_DEV_ENV:-0}";
PHP_CLI_SMTP_HOST="${PHP_CLI_SMTP_HOST:-localhost}";
PHP_CLI_SMTP_PORT="${PHP_CLI_SMTP_PORT:-587}";
PHP_CLI_SMTP_USER="${PHP_CLI_SMTP_USER:-root}";
PHP_CLI_SMTP_PASSWORD="${PHP_CLI_SMTP_PASSWORD:-password}";
PHP_CLI_SMTP_FROM="${PHP_CLI_SMTP_FROM:-root@localhost}";
PHP_CLI_SMTP_DOMAIN="${PHP_CLI_SMTP_DOMAIN:-localhost}";
PHP_CLI_MYSQL_SOCKET="${PHP_CLI_MYSQL_SOCKET:-}";
PHP_CLI_LOG_ERRORS="${PHP_CLI_LOG_ERRORS:-}";
PHP_CLI_ERROR_REPORTING="${PHP_CLI_ERROR_REPORTING:-}";
PHP_CLI_DISPLAY_ERRORS="${PHP_CLI_DISPLAY_ERRORS:-}";
PHP_CLI_IS_CRONTAB_ENABLED="${PHP_CLI_IS_CRONTAB_ENABLED:-0}";
PHP_CLI_USER_ID="${PHP_CLI_USER_ID:-0}";
PHP_CLI_GROUP_ID="${PHP_CLI_GROUP_ID:-0}";
PHP_CLI_IS_XDEBUG_ENABLED="${PHP_CLI_IS_XDEBUG_ENABLED:-0}";
PHP_CLI_XDEBUG_HOST="${PHP_CLI_XDEBUG_HOST:-localhost}";
PHP_CLI_XDEBUG_PORT="${PHP_CLI_XDEBUG_PORT:-9000}";
PHP_CLI_XDEBUG_IDEKEY="${PHP_CLI_XDEBUG_IDEKEY:-PHPSTORM}";

PHP_CLI_INI_DIR="/usr/local/etc/php";
PHP_CLI_CONFIG_FILE="${PHP_CLI_INI_DIR}/conf.d/php.ini";

sed -i "s#%PHP_MYSQL_SOCKET%#${PHP_CLI_MYSQL_SOCKET}#g" "$PHP_CLI_CONFIG_FILE";
sed -i "s#%PHP_LOG_ERRORS%#${PHP_CLI_LOG_ERRORS}#g" "$PHP_CLI_CONFIG_FILE";
sed -i "s#%PHP_ERROR_REPORTING%#${PHP_CLI_ERROR_REPORTING}#g" "$PHP_CLI_CONFIG_FILE";
sed -i "s#%PHP_DISPLAY_ERRORS%#${PHP_CLI_DISPLAY_ERRORS}#g" "$PHP_CLI_CONFIG_FILE";

PHP_CLI_SMTP_CONFIG_FILE="/etc/msmtprc";

sed -i "s#%SMTP_HOST%#${PHP_CLI_SMTP_HOST}#g" "$PHP_CLI_SMTP_CONFIG_FILE";
sed -i "s#%SMTP_PORT%#${PHP_CLI_SMTP_PORT}#g" "$PHP_CLI_SMTP_CONFIG_FILE";
sed -i "s#%SMTP_USER%#${PHP_CLI_SMTP_USER}#g" "$PHP_CLI_SMTP_CONFIG_FILE";
sed -i "s#%SMTP_PASSWORD%#${PHP_CLI_SMTP_PASSWORD}#g" "$PHP_CLI_SMTP_CONFIG_FILE";
sed -i "s#%SMTP_FROM%#${PHP_CLI_SMTP_FROM}#g" "$PHP_CLI_SMTP_CONFIG_FILE";
sed -i "s#%SMTP_DOMAIN%#${PHP_CLI_SMTP_DOMAIN}#g" "$PHP_CLI_SMTP_CONFIG_FILE";

rm -f "${PHP_CLI_INI_DIR}/php.ini";

if [ 1 = "$PHP_CLI_IS_DEV_ENV" ]
then
  cp "${PHP_CLI_INI_DIR}/php.ini-development" "${PHP_CLI_INI_DIR}/php.ini";
else
  cp "${PHP_CLI_INI_DIR}/php.ini-production" "${PHP_CLI_INI_DIR}/php.ini";
fi

if [ 1 = "$PHP_CLI_IS_XDEBUG_ENABLED" ]
then
  rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini;
  cp /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.original /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini;
  {
    echo "xdebug.mode = debug";
    echo "xdebug.client_host = ${PHP_CLI_XDEBUG_HOST}";
    echo "xdebug.client_port = ${PHP_CLI_XDEBUG_PORT}";
    echo "xdebug.idekey = ${PHP_CLI_XDEBUG_IDEKEY}";
    echo "xdebug.discover_client_host = 1";
    echo "xdebug.show_error_trace = 1";
    echo "xdebug.start_with_request = yes";
  } >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini;
else
  rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini;
fi

if [ 0 != "$PHP_CLI_USER_ID" ]
then
  PHP_CLI_USER=$(getent passwd "$PHP_CLI_USER_ID" | cut -d: -f1);
  HOME="/home/${PHP_CLI_USER}";
  mkdir -p "${HOME}";
  chown "${PHP_CLI_USER_ID}:${PHP_CLI_GROUP_ID}" "${HOME}";
fi

PHP_CLI_USER="${PHP_CLI_USER:-root}";

if [ 1 = "$PHP_CLI_IS_CRONTAB_ENABLED" ]
then
  crontab -u "$PHP_CLI_USER" /etc/periodic/crontab;
fi

exec "$@";
