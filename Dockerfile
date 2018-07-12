# Docker-Moodle
# Dockerfile for moodle instance. more dockerish version of https://github.com/sergiogomez/docker-moodle
# Forked from Jon Auer's docker version. https://github.com/jda/docker-moodle
FROM ubuntu:16.04
MAINTAINER Andrea Pellegrini <uschti@gmail.com>

VOLUME ["/var/moodledata"]
EXPOSE 80 443

# Keep upstart from complaining
# RUN dpkg-divert --local --rename --add /sbin/initctl
# RUN ln -sf /bin/true /sbin/initctl

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Database info and other connection information derrived from env variables. See readme.
# Set ENV Variables externally Moodle_URL should be overridden.
ENV MOODLE_URL http://127.0.0.1
ENV MOODLE_MEMORY_LIMIT 10M
ENV MOODLE_POST_MAX_SIZE 10M
ENV MOODLE_UPLOAD_MAX_FILESIZE 10M

RUN apt-get update && \
	apt-get -y install mysql-client pwgen python-setuptools iputils-ping curl git unzip apache2 php \
		php-gd libapache2-mod-php postfix wget supervisor php-pgsql libcurl3 \
		libcurl3-dev php-curl php-xmlrpc php-intl php-mysql git-core php-xml php-mbstring php-zip php-soap cron php7.0-ldap && \
	cd /tmp && \
	git clone -b MOODLE_35_STABLE git://git.moodle.org/moodle.git --depth=1 && \
	mv /tmp/moodle/* /var/www/html/ && \
	rm /var/www/html/index.html && \
	chown -R www-data:www-data /var/www/html

COPY moodle-config.php /var/www/html/config.php

ADD ./foreground.sh /etc/apache2/foreground.sh
ADD ./env_secrets_expand.sh /etc/apache2/env_secrets_expand.sh

RUN chmod +x /etc/apache2/foreground.sh && chmod +x /etc/apache2/env_secrets_expand.sh

#cron
COPY moodlecron /etc/cron.d/moodlecron
RUN chmod 0644 /etc/cron.d/moodlecron

# Enable SSL, moodle requires it
RUN a2enmod ssl && a2ensite default-ssl  #if using proxy dont need actually secure connection

# autorise .htaccess files
RUN a2enmod rewrite && a2enmod env
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Add custom .htaccess file with PHP upload size limit ovverride by ENV var MOODLE_MAX_UPLOAD_SIZE
RUN touch /var/www/html/.htaccess
RUN chmod 0444 /var/www/html/.htaccess

# Cleanup, this is ran to reduce the resulting size of the image.
RUN apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/dpkg/* /var/lib/cache/* /var/lib/log/*

CMD ["/etc/apache2/foreground.sh"]
