FROM alpine:3.23

RUN apk update && apk add --no-cache mariadb mariadb-client

# Create the MariaDB runtime directory and allow the MariaDB process to use it
# Configure MariaDB to listen on all network interfaces
# Enable network connections by disabling MariaDB's skip-networking option
RUN mkdir -p /var/run/mysqld && \
    chmod 777 /var/run/mysqld && \
    { \
        echo '[mysqld]'; \
        echo 'bind-address=0.0.0.0'; \
    } | tee /etc/my.cnf.d/extra.cnf && \
    sed -i "s|skip-networking|skip-networking=0|g" \
    /etc/my.cnf.d/mariadb-server.cnf

COPY requirements/mariadb/conf/setup_db.sh /usr/local/bin/setup_db.sh
COPY requirements/mariadb/tools/db.sh /usr/local/bin/db.sh

RUN chmod +x /usr/local/bin/setup_db.sh /usr/local/bin/db.sh

EXPOSE 3306
USER mysql
ENTRYPOINT ["/usr/local/bin/db.sh"]
CMD ["/usr/bin/mysqld", "--skip-log-error"]
