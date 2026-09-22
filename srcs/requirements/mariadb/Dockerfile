FROM alpine:3.23

RUN apk update && apk add --no-cache mariadb mariadb-client

RUN mkdir -p /var/run/mysqld && \
    chmod 777 /var/run/mysqld && \
    { \
        echo '[mysqld]'; \
        echo 'bind-address=0.0.0.0'; \
    } | tee /etc/my.cnf.d/docker.cnf && \
    sed -i "s|skip-networking|skip-networking=0|g" \
    /etc/my.cnf.d/mariadb-server.cnf

COPY requirements/mariadb/conf/create_db.sh /usr/local/bin/create_db.sh
COPY requirements/mariadb/tools/db.sh /usr/local/bin/db.sh

RUN chmod +x /usr/local/bin/create_db.sh /usr/local/bin/db.sh

EXPOSE 3306

USER mysql

ENTRYPOINT ["/usr/local/bin/db.sh"]

CMD ["/usr/bin/mysqld", "--skip-log-error"]

