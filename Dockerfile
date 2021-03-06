FROM centos:centos6
MAINTAINER Takaya Yoshida

ENV IP __YOUR_IP_ADDRESS_HERE__
ENV PW __YOUR_PASSWORD_HERE__

RUN yum update -y
RUN yum install wget -y
RUN wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm ;\
    wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm ;\
    wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm ;\
    rpm -ivh epel-release-6-8.noarch.rpm remi-release-6.rpm rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
RUN yum --enablerepo=remi,epel install sudo openssh-server syslog httpd httpd-devel php php-devel php-pear php-mysql php-gd php-mbstring php-pecl-imagick php-pecl-memcache monit mysql-server phpmyadmin -y

ADD fuelphp.conf /etc/httpd/conf.d/fuelphp.conf
ADD monit.httpd /etc/monit.d/httpd
ADD monit.sshd /etc/monit.d/sshd
ADD monit.mysqld /etc/monit.d/mysqld
ADD monit.conf /etc/monit.conf
RUN chown -R root:root /etc/monit.d/ /etc/monit.conf
RUN chmod -R 600 /etc/monit.conf

RUN sed -ri "s/^UsePAM yes/#UsePAM yes/" /etc/ssh/sshd_config
RUN sed -ri "s/^#UsePAM no/UsePAM no/" /etc/ssh/sshd_config
RUN sed -rie "9i Allow from $IP" /etc/httpd/conf.d/phpmyadmin.conf
RUN sed -ri "s/%%IPADDRESS%%/$IP/" /etc/monit.conf
RUN sed -ri "s/cfg\['blowfish_secret'\] = ''/cfg['blowfish_secret'] = '`uuidgen`'/" /usr/share/phpmyadmin/config.inc.php

RUN chmod 755 /var/log/httpd
RUN touch /etc/sysconfig/network

RUN mkdir -m 700 /root/.ssh
ADD authorized_keys /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys && chown root:root /root/.ssh/authorized_keys

RUN useradd lamp && echo "lamp:$PW" | chpasswd
RUN echo 'lamp ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/lamp

RUN service mysqld start && \
    /usr/bin/mysqladmin -u root password "$PW"

RUN echo 'date.timezone = "Asia/Tokyo"' >> /etc/php.ini
ADD composer.phar /var/www/composer.phar
RUN php /var/www/composer.phar create-project fuel/fuel:dev-1.7/master /var/www/fuelphp
