FROM centos:7

ARG http_proxy=http://wwwproxy.hud.ac.uk:3128
ARG https_proxy=http://wwwproxy.hud.ac.uk:3128

RUN yum -y install *openldap* migrationtools git

RUN mv /etc/openldap /etc/openldap.dist

COPY entrypoint.sh /entrypoint.sh

EXPOSE 389

ENTRYPOINT ["/entrypoint.sh"]

CMD ["slapd", "-d", "32768", "-u", "ldap", "-g", "ldap"]