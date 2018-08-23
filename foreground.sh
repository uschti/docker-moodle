#!/bin/bash

echo "placeholder" > /var/moodledata/placeholder
chown -R www-data:www-data /var/moodledata
chmod 777 /var/moodledata

read pid cmd state ppid pgrp session tty_nr tpgid rest < /proc/self/stat
trap "kill -TERM -$pgrp; exit" EXIT TERM KILL SIGKILL SIGTERM SIGQUIT

#start up cron
/usr/sbin/cron

source /etc/apache2/envvars
source /etc/apache2/env_secrets_expand.sh

#Write htaccess ENV vars
echo "php_value memory_limit $MOODLE_MEMORY_LIMIT" >> /var/www/html/.htaccess
echo "php_value post_max_size $MOODLE_POST_MAX_SIZE" >> /var/www/html/.htaccess
echo "php_value upload_max_filesize $MOODLE_UPLOAD_MAX_FILESIZE" >> /var/www/html/.htaccess

# Copy the theme to the volume if the folder is empty
DIR="/var/www/html/theme"
SRC_DIR="/var/www/html/theme.ORIG"
if [ "$(ls -A $DIR)" ]; then
    echo "No need to copy the theme folder, use the already present one!"
else
    echo "Copy the theme folder from $SRC_DIR to $DIR.."
    cp -r "$SRC_DIR/." "$DIR/"
fi

# Start Apache
tail -F /var/log/apache2/* &
exec apache2 -D FOREGROUND
