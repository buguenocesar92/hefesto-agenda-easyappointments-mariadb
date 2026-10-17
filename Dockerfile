FROM alextselegidis/easyappointments:1.6.0@sha256:ab35b8872d5d3328fa3afb641a89a75f3c6f96f3fb98d6d6d3447fff9d357fa1
USER root
RUN mkdir -p /opt/hefesto && cp /var/www/html/application/config/config.php /opt/hefesto/config-base.php
COPY container/ /opt/hefesto/
RUN php -l /opt/hefesto/configure.php && chmod +x /opt/hefesto/start.sh
ENTRYPOINT ["/opt/hefesto/start.sh"]
