FROM centos:7

RUN yum -y install *openldap* migrationtools git make

# install n
WORKDIR /
RUN git clone https://github.com/tj/n.git \
    && cd n \
    && make \
    && make install \
    && cd .. \
    && rm -r n

# use n to install node
RUN n lts

# use npm to install config-templater
RUN npm install -g yml2ldif

RUN mv /etc/openldap /etc/openldap.dist

COPY entrypoint.sh /entrypoint.sh

EXPOSE 389

ENTRYPOINT ["/entrypoint.sh"]

CMD ["slapd", "-d", "32768", "-u", "ldap", "-g", "ldap"]
